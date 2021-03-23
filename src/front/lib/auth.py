# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
# Login Code from Examples at: https://github.com/Azure-Samples/ms-identity-python-webapp
import msal
import os
from starlette.requests import Request

# TODO: Change all below items to keyvault reads

CLIENT_ENV_ID = os.getenv("CLIENT_ID", "None")

CLIENT_ENV_SECRET = os.getenv("CLIENT_SECRET", "None")

AUTHORITY = "https://login.microsoftonline.com/" + os.getenv("TENANT_ID")

# You can find the proper permission names from this document
# https://docs.microsoft.com/en-us/graph/permissions-reference
SCOPE = ["User.ReadBasic.All"]


def load_cache(request: Request):
    """
     Process a cache that exists in the users cookies

    :param request: request object sent to the calling functions body
    :return: Returns the processed cache from the users session
    """
    cache = msal.SerializableTokenCache()
    cookie_cache = request.cookies.get("token_cache")
    if cookie_cache:
        cache.deserialize(cookie_cache)
    return cache


def build_msal_app(cache=None, client_id=CLIENT_ENV_ID, authority=None, secret=CLIENT_ENV_SECRET):
    """
     Build the MSAL application for providing authentication

    :param cache: provides the cache from the stored user cookies
    :param client_id: The client ID of the AAD application being used for login
    :param authority: Azure Authority for the application
    :param secret: Client Secret of the AAd application being used for login
    :return: Returns the app block used to facilitate login
    """
    return msal.ConfidentialClientApplication(
        client_id, authority=authority or AUTHORITY,
        client_credential=secret, token_cache=cache)


def build_auth_code_flow(authority=None, scopes=None, redirect_uri=None, client_id=CLIENT_ENV_ID, secret=CLIENT_ENV_SECRET):
    """
     Use the MSAL app to build a flow cache to facilitate logging in

    :param authority: Azure Authority
    :param scopes: The scopes being requested for this authorization
    :param redirect_uri: The redirect URI to provide to the AAD login, must be a URI registered to the AAD app
    :param client_id: The client ID of the AAD application being used for login
    :param secret: Client Secret of the AAd application being used for login
    :return: Returns the app flow code block used to provide URL's for login
    """
    return build_msal_app(client_id=client_id, authority=authority, secret=secret).initiate_auth_code_flow(
        scopes or [],
        redirect_uri=redirect_uri)

"""
#TODO: purge when sure this won't be useful
Unused Example from MSAL examples
def get_token_from_cache(request: Request, scope=None):
    cache = load_cache(request.cookies.get("token_cache"))  # This web app maintains one cache per session
    cca = build_msal_app(cache=cache)
    accounts = cca.get_accounts()
    if accounts:  # So all account(s) belong to the current signed-in user
        result = cca.acquire_token_silent(scope, account=accounts[0])
        return result
"""