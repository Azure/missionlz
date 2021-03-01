# Login Code from Examples at: https://github.com/Azure-Samples/ms-identity-python-webapp
import msal
import os
from starlette.requests import Request

# TODO: Change all below items to keyvault reads

CLIENT_ID = os.getenv("CLIENT_ID") # Application (client) ID of app registration

CLIENT_SECRET = os.getenv("CLIENT_SECRET")

AUTHORITY = "https://login.microsoftonline.com/" + os.getenv("TENANT_ID")

# You can find the proper permission names from this document
# https://docs.microsoft.com/en-us/graph/permissions-reference
SCOPE = ["User.ReadBasic.All"]


def load_cache(request: Request):
    cache = msal.SerializableTokenCache()
    cookie_cache = request.cookies.get("token_cache")
    if cookie_cache:
        cache.deserialize(cookie_cache)
    return cache


def build_msal_app(cache=None, client_id=CLIENT_ID, authority=None, secret=None):
    return msal.ConfidentialClientApplication(
        client_id, authority=authority or AUTHORITY,
        client_credential=secret, token_cache=cache)


def build_auth_code_flow(authority=None, scopes=None, redirect_uri=None):
    return build_msal_app(authority=authority, secret=CLIENT_SECRET).initiate_auth_code_flow(
        scopes or [],
        redirect_uri=redirect_uri)


def get_token_from_cache(request: Request, scope=None):
    cache = load_cache(request.cookies.get("token_cache"))  # This web app maintains one cache per session
    cca = build_msal_app(cache=cache)
    accounts = cca.get_accounts()
    if accounts:  # So all account(s) belong to the current signed-in user
        result = cca.acquire_token_silent(scope, account=accounts[0])
        return result
