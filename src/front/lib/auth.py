# Login Code from Examples at: https://github.com/Azure-Samples/ms-identity-python-webapp
import msal
import os
from starlette.requests import Request

CLIENT_ID = os.getenv("CLIENT_ID") # Application (client) ID of app registration

CLIENT_SECRET = os.getenv("CLIENT_SECRET")
# In a production app, we recommend you use a more secure method of storing your secret,
# like Azure Key Vault. Or, use an environment variable as described in Flask's documentation:
# https://flask.palletsprojects.com/en/1.1.x/config/#configuring-from-environment-variables
# CLIENT_SECRET = os.getenv("CLIENT_SECRET")
# if not CLIENT_SECRET:
#     raise ValueError("Need to define CLIENT_SECRET environment variable")

AUTHORITY = "https://login.microsoftonline.com/72f988bf-86f1-41af-91ab-2d7cd011db47"  # For multi-tenant app
# AUTHORITY = "https://login.microsoftonline.com/Enter_the_Tenant_Name_Here"

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
