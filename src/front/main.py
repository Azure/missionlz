# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.
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
import os
import re
import sys
from lib.utils import *

app = FastAPI()

app.mount("/static", StaticFiles(directory="static"), name="static")

# Setup keyvault accesses to gather keys
keyVaultName = os.getenv("KEYVAULT_ID", None)

if keyVaultName:
    keyVaultUrl = "https://{}.vault.azure.net/".format(keyVaultName)

    # This will use your Azure Managed Identity
    credential = DefaultAzureCredential()
    secret_client = SecretClient(
        vault_url=keyVaultUrl,
        credential=credential)

static_location = '/static/'

@app.get("/")
async def home(request: Request):
    """
     Primary landing section for the app

    :param request: request object sent in the post body when accessing this API
    :return: Will return a rendered HTML page
    """
    # Handle the rendering of the login url
    login_url = ""
    user = ""
    flow = request.cookies.get("flow")
    if not request.cookies.get("user"):
        if keyVaultName:
            flow = auth.build_auth_code_flow(client_id=secret_client.get_secret("login-app-clientid").value,
                                             secret=secret_client.get_secret("login-app-pwd").value, scopes=auth.SCOPE)
        else:
            flow = auth.build_auth_code_flow(scopes=auth.SCOPE)
        login_url = flow["auth_uri"]
    else:
        user = json.loads(request.cookies.get("user"))

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
        link(rel='stylesheet', href=static_location + 'custom.css')

    # Fill in the single page app template with forms and sections
    with doc:
        # Case for each variable type in JSON definition
        with div(cls="navbar navbar-expand-lg fixed-top navbar-dark bg-primary"):
            with div(cls="container"):
                a("Mission LZ", cls="navbar-brand", href="#")
                with div(cls='text-right'):
                    if user:
                        a("Logout " + user["name"], href="/logout", cls="btn btn-outline-secondary")

        with div(cls="container"):
            with div(cls="page-header"):
                if config:
                    pass
                    # Parse each config element in a switch to generate a section of forms for it
                else:
                    build_form(find_config())


        # Modal
        with div(cls="modal fade", data_backdrop="static", id="promptModal", tabindex="-1", role="dialog", aria_hidden="true"):
            with div(cls="modal-dialog modal-dialog-centered", role="document"):
                with div(cls="modal-content"):
                    with div(cls="modal-header"):
                        h5("Modal Title", cls="modal-title")
                    div("Modal Content", cls="modal-body")
                    with div(cls="modal-footer"):
                        button("Close", id="modBtn", type="button", cls="btn btn-secondary", data_dismiss="modal")

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
              modal.find('#modBtn').hide()
            })
            $('#promptModal').modal('show')
        }
      
        $(document).ready(function(){
            $('#showTenant').click(function(){
                promptTenant()
            })
               
            logged_in = readCookie("user")
        
            if(!logged_in || $.trim(logged_in) == ""){
              promptLogin()
            }
        })
        $("input").change(function(){
	        $("input[name="+ this.name +"]").val(this.value)
        })
        """)

    response = HTMLResponse(content=str(doc), status_code=200)
    response.set_cookie("flow", json.dumps(flow), expires=3600)
    return response

# Display currently cached creds
@app.get("/creds")
async def display_creds(request: Request):
    """
     Process the body request for debugging purposes if there's a user issue with Azure

    :param request: request object sent in the post body when accessing this API
    :return: Will return a json block with relevant debugging data for the user session
    """
    result = request.cookies.get("flow")
    user = request.cookies.get("user")
    if keyVaultName:
        test_value = secret_client.get_secret("login-app-clientid")
    return JSONResponse({"creds": user, "flow": result, "test_val":test_value.value})

# Process Logout
@app.get("/logout")
async def process_logout():
    """
     Purge the login information from the users session/cookie data

    :return: Redirect to main body
    """
    # Simply destroy the cookies in this session and get rid of the creds, redirect to landing
    response=RedirectResponse("/")  # Process the destruction from main app/test result
    response.delete_cookie("user")
    response.delete_cookie("flow")
    return response

# API To Capture the redirect from Azure
@app.get("/redirect")
async def capture_redirect(request: Request):
    """
     Process the request body that's returned from AAD.  This will process the login items to acquire user in info

    :param request: request object sent in the post body when accessing this API
    :return: Will either redirect the user back to the main page, or display an error
    """
    try:
        cache = auth.load_cache(request)
        if keyVaultName:
            result = auth.build_msal_app(cache, client_id=secret_client.get_secret("login-app-clientid").value, secret=secret_client.get_secret("login-app-pwd").value).acquire_token_by_auth_code_flow(
                    dict(json.loads(request.cookies.get("flow"))), dict(request.query_params))
        else:
            result = auth.build_msal_app(cache).acquire_token_by_auth_code_flow(
                dict(json.loads(request.cookies.get("flow"))), dict(request.query_params))
        if "error" in result:
            response = JSONResponse({"status": "error", "result": result})
        else:
            #response = JSONResponse({"status": "success", "result": result})
            response = RedirectResponse("/")
            response.set_cookie("user", json.dumps(result.get("id_token_claims")), expires=3600)
    except ValueError as e:
        #TODO: Add some more prettiness to the UI to allow for the CSRF errors to display
        response = JSONResponse({"status": "error", "result": "Possible CSRF related error"+str(e)})
    return response


# Execute processes the form values entered by the user and generates the TF JSON file
@app.post("/execute")
async def process_input(request: Request):
    """
     Process the dynamic form that's posted to this API and perform the required processing
     Initiate an async job for executing terraform

    :param request: request object sent in the post body when accessing this API
    :return: Will return success if all items are completed
    """
    dynamic_form = await request.form()
    form_values = dict(dynamic_form)
    #TODO: Possibly revisit for stronger security
    if not request.cookies.get("user") or not request.cookies.get("flow"):
        return JSONResponse(content={"status": "Error: User Not Logged In"}, status_code=200)

    # Reload form configs:
    form_config = find_config()

    # Load tfvars initial files
    tf_json = find_config(extension="tfvars.json")

    #Create a map based on str maps in the form config files
    maps = {}
    for _, config_doc in form_config.items():
        for _, config in config_doc.items():
            if "str_maps" in config:
                for strm, smap in config["str_maps"].items():
                    maps[strm] = form_values[smap]
    
        #Evaluate maps across loaded jsons
    for f_name, doc in tf_json.items():
        temp_dump = json.dumps(doc)
        for strm, smap in maps.items():
            temp_dump = temp_dump.replace("{" + strm + "}", smap)
        tf_json[f_name] = json.loads(temp_dump)

    # Process all form keys:
    form_dump = json.dumps(form_values)
    for key, smap in maps.items():
       form_dump.replace("{"+key+"}", smap)
    form_values = json.loads(form_dump)

    # Write the values to the correct locations in the memory loaded json files
    for key, value in form_values.items():
        for _, doc in tf_json.items():
            dotted_write(key, value, doc)

    # Loop all open TF documents and write them out
    for f_name, doc in tf_json.items():
        json.dump(doc, open(os.path.basename(f_name), "w+"))


    #TODO: Execute Terraform

    return JSONResponse(content=json.dumps(dict(dynamic_form)), status_code=200)
    #return JSONResponse(content={"status": "success"}, status_code=200)


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


# Primary entry for unvicorn
# TODO: Replace with docker FlaskAPI Base image later
if __name__ == "__main__":
    port = 80
    if len(sys.argv) > 1:
        port = int(sys.argv[1])
    uvicorn.run(app, host='0.0.0.0', port=port, debug=True)
