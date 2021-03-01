import json
from datetime import datetime, timedelta
import dominate
import uvicorn
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient
from dominate.tags import *
from fastapi import FastAPI
from fastapi.responses import HTMLResponse, JSONResponse, RedirectResponse
from fastapi.staticfiles import StaticFiles
from starlette.requests import Request
from lib import auth

app = FastAPI()

app.mount("/static", StaticFiles(directory="static"), name="static")


@app.get("/")
async def home(request: Request):
    static_location = '/static/'

    # Handle the rendering of the login url
    login_url = ""
    flow = request.cookies.get("flow")
    if not request.cookies.get("user"):
        flow = auth.build_auth_code_flow(scopes=auth.SCOPE)
        login_url = flow["auth_uri"]

    # Modal Templates
    tenant_input_html = "Please enter the Tenant ID for the Azure Instance you are using.  This is needed to set up" \
                        "authentication.  You can find this by typing \"Tenant\" into the Azure Portal for where you" \
                        " intend to deploy your infrastructure." + \
                        br().render() + \
                        div(
                            input_("Tenant ID", id="tenantId", cls="form-control", aria_label="Small",
                                   aria_describedby="inputGroup-sizing-sm"),
                            div(
                                button("Save Id", type="button", id="saveTenant",
                                       cls="btn btn-outline-secondary"),
                                cls="input-group-append"),
                            cls="input-group input-group-sm mb-3").render(pretty=False)

    login_input_html = "Click the below button to initiate AAD authentication" + br().render() + div(
                            a("Login", href=login_url),
                            cls="input-group input-group-sm mb-3").render(pretty=False)

    try:
        config = json.load(open("form_config.json"))
    except FileNotFoundError:
        config = None

    # Initiate the HTML Document
    doc = dominate.document(title="Mission LZ")

    # Set initial style sheet in HTML doc head
    with doc.head:
        link(rel='stylesheet', href=static_location + 'bootstrap.min.css')
        style(""".page-header{
                margin-top: 80px;Oh go
                margin-bottom: 25px;
                }
                """)

    # Fill in the single page app template with forms and sections
    with doc:
        # Case for each variable type in JSON definition
        with div(cls="navbar navbar-expand-lg fixed-top navbar-dark bg-primary"):
            sections = ["Subscriptions", "Tier 0", "Tier 1", "Tier 3"]
            with div(cls="container"):
                a("Mission LZ", cls="navbar-brand", href="#")
                with div(cls='collapse navbar-collapse'):
                    ul((li(a(x, href="#", cls="nav-link"), cls="nav-item") for x in sections), cls="navbar-nav mr-auto")
                    button("Change Tenant ID", type="button", id="showTenant", cls="btn btn-outline-secondary")
        with div(cls="container"):
            with div(cls="page-header"):
                with div(cls="row"):
                    div("Below are all of the items needed to generate your Azure Infrastructure. Items all related to "
                             "an input variable within Terraform.  Everything has a default and can be generated as is", cls="col")
                if config:
                    pass
                    # Parse each config element in a switch to generate a section of forms for it
                else:
                    tiers = ["Tier 0 - Identity, Auth Services", "Tier 1 - Infrastructure Operations", "Tier 2: DevSecOps & Shared Services", "Tier 3-N - Team Subscriptions"]
                    with div(cls="row"):
                        with div(cls='col-sm'):

                            items = ('Action', 'Another action',
                                     'Yet another action')
                            select(option(x, value=x) for x in items)

        # Modal
        with div(cls="modal fade", id="promptModal", tabindex="-1", role="dialog", aria_hidden="true"):
            with div(cls="modal-dialog modal-dialog-centered", role="document"):
                with div(cls="modal-content"):
                    with div(cls="modal-header"):
                        h5("Modal Title", cls="modal-title")
                    div("Modal Content", cls="modal-body")
                    with div(cls="modal-footer"):
                        button("Close", type="button", cls="btn btn-secondary", data_dismiss="modal")

        # Include the Javascript Files in the output HTML
        script(src=static_location + 'jquery-3.5.1.min.js')
        script(src=static_location + 'bootstrap.bundle.min.js')
        script(src=static_location + 'custom.js')

        script().add_raw_string("""
        function promptLogin() {
            $('#promptModal').on('show.bs.modal', function (event) {
              var modal = $(this)
              modal.find('.modal-title').text('Login')
              modal.find('.modal-body').html('""" + login_input_html + """')
            })
            $('#promptModal').modal('show')
        }
      
        $(document).ready(function(){
            $('#showTenant').click(function(){
                promptTenant()
            })
               
            logged_in = readCookie("logged_in")
        
            if(!logged_in || $.trim(logged_in) == ""){
              promptLogin()
            }
        })""")

    response = HTMLResponse(content=str(doc), status_code=200)
    response.set_cookie("flow", flow, expires=3600)
    return response

# Display currently cached creds
@app.get("/creds")
async def display_creds(request: Request):
    return JSONResponse({"creds": auth.load_cache(request)})

# Process Logout
@app.get("/logout")
async def process_logout():
    # Simply destroy the cookies in this session and get rid of the creds, redirect to landing
    response = JSONResponse({"result": "Session Destroyed"})  # Process the destruction from main app/test result
    #response = RedirectResponse("/")   # Optional method to link and redirect to app
    response.delete_cookie("user")
    response.delete_cookie("flow")
    return response

# API To Capture the redirect from Azure
@app.get("/redirect")
async def capture_redirect(request: Request):
    try:
        cache = auth.load_cache(request)
        result = auth.build_msal_app(cache).acquire_token_by_auth_code_flow(
            request.cookies.get("flow"), request.query_params)
        if "error" in result:
            response = JSONResponse({"status": "error", "result": result})
        else:
            response = JSONResponse({"status": "success", "result": result})
            response.set_cookie("user", result.get("id_token_claims"), expires=3600)
    except ValueError:
        response = JSONResponse({"status": "error", "result": "Possible CSRF related error"})
    return response


# Execute processes the form values entered by the user and generates the TF JSON file
@app.get("/execute")
async def process_terraform():

    return JSONResponse(content={"status": "Test in Place, no processing done"}, status_code=200)


# Execute a poll for the contents of a specific job,  logs from terraform execution will be stored as text with
# a job key ast he file name?
@app.get("/poll")
async def poll_results(job_num: int):
    """
    Pol results is an async definition used by the /poll API query with a get query for job_num

    :param job_num: HTML GET Query parameter, the job num generated by process
    :return: will return the current contents of the results text file retrieved from job_num
    """
    try:
        with open("results/" + job_num) as res:
            return JSONResponse({"results": res.read()}, status_code=200)
    except:
        return JSONResponse({"results": "No content for that job_num"}, status_code=200)


# ####   PYTHON TEST ENDPOINTS   ##### #
# Test code for testing keyvault access using system creds
@app.get("/testaccess")
async def access_test():
    my_vault_name = "tfkv-62d1e9791981"
    my_vault_url = "https://{}.vault.azure.net/".format(my_vault_name)
    my_secret_name = "testkey"

    # This will use your Azure Managed Identity
    credential = DefaultAzureCredential()
    secret_client = SecretClient(
        vault_url=my_vault_url,
        credential=credential)
    secret = secret_client.get_secret(my_secret_name)
    return JSONResponse({"Test-Key Result": secret.value}, status_code=200)


# Test harness for cookie read (Use this for debugging)
@app.get("/readcookies")
async def cookies_read_test(request: Request):
    return JSONResponse({"CookieVal": request.cookies.get("testcookies")})


# Test harness for cookie write (Use this for debugging)
@app.get("/testcookies")
async def cookies_write_test():
    response = JSONResponse({"result": "Setting a Cookie Value for Testing"})
    response.set_cookie(key="testcookies", value="TestValue", expires=3600)
    return response
# ####  END TESTS  #### #


# Primary entry for unvicorn
# TODO: Replace with docker FlaskAPI Base image later
if __name__ == "__main__":
    uvicorn.run(app, host='0.0.0.0', port=80, debug=True)
