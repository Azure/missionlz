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
import subprocess
from subprocess import call
import asyncio
import os
import re
import sys
from lib.utils import *

app = FastAPI()

app.mount("/static", StaticFiles(directory="static"), name="static")

# Setup keyvault accesses to gather keys
cloud_name = os.getenv("MLZ_CLOUDNAME", None)
azure_ad_endpoint = os.getenv("MLZ_ACTIVEDIRECTORY", None)
keyVaultName = os.getenv("KEYVAULT_ID", None)
keyVaultDns = os.getenv("MLZ_KEYVAULTDNS", None)

subprocess.check_call(["az", "cloud", "set", "-n", cloud_name])

if keyVaultName:
    keyVaultUrl = "https://{}{}/".format(keyVaultName, keyVaultDns)

    # This will use your Azure Managed Identity
    credential = DefaultAzureCredential(authority=azure_ad_endpoint)
    secret_client = SecretClient(
        vault_url=keyVaultUrl,
        credential=credential)

static_location = '/static/'
exec_output = os.path.join(os.getcwd(), "exec_output", "exec.txt")

if not os.path.exists(os.path.join(os.getcwd(), "config_output")):
    os.mkdir(os.path.join(os.getcwd(), "config_output"))

if not os.path.exists(os.path.join(os.getcwd(), "exec_output")):
    os.mkdir(os.path.join(os.getcwd(), "exec_output"))

if not os.path.exists(exec_output):
    with open(exec_output, "w+") as f:
        f.write("")


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
        with div(cls="modal fade", data_backdrop="static", id="promptModal", tabindex="-1", role="dialog",
                 aria_hidden="true"):
            with div(cls="modal-dialog modal-dialog-centered modal-lg", role="document"):
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

        var interval = null
        function retrieve_results() {
          $.ajax({
           type: "GET",
           url: "/poll",
           success: function(msg){
             $("#terminal").text(msg);
           }
         });
        }

        function submitForm(){
            interval = setInterval(retrieve_results, 2000);
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

        $(document).on('submit', '#terraform_config', function(e) {
            $('#promptModal').on('show.bs.modal', function (event) {
              var modal = $(this)
              modal.find('.modal-title').text('Polling execution results: (Box May Stay Blank for an extended amount of time)')
              modal.find('.modal-body').html('<pre id="terminal"></pre>')
              modal.find('#modBtn').show()
              modal.find('#modBtn').click(function(){
                clearInterval(interval)
              })
            })
            $('#promptModal').modal('show')
             $.ajax({
                url: $(this).attr('action'),
                type: $(this).attr('method'),
                data: $(this).serialize(),
                success: function(html) {
                    submitForm()
                }
            });
            e.preventDefault();
        });

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
    return JSONResponse({"creds": user, "flow": result, "test_val": test_value.value})


# Process Logout
@app.get("/logout")
async def process_logout():
    """
     Purge the login information from the users session/cookie data

    :return: Redirect to main body
    """
    # Simply destroy the cookies in this session and get rid of the creds, redirect to landing
    response = RedirectResponse("/")  # Process the destruction from main app/test result
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
            result = auth.build_msal_app(cache, client_id=secret_client.get_secret("login-app-clientid").value,
                                         secret=secret_client.get_secret(
                                             "login-app-pwd").value).acquire_token_by_auth_code_flow(
                dict(json.loads(request.cookies.get("flow"))), dict(request.query_params))
        else:
            result = auth.build_msal_app(cache).acquire_token_by_auth_code_flow(
                dict(json.loads(request.cookies.get("flow"))), dict(request.query_params))
        if "error" in result:
            response = JSONResponse({"status": "error", "result": result})
        else:
            # response = JSONResponse({"status": "success", "result": result})
            response = RedirectResponse("/")
            response.set_cookie("user", json.dumps(result.get("id_token_claims")), expires=3600)
    except ValueError as e:
        response = JSONResponse({"status": "error", "result": "Possible CSRF related error" + str(e)})
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
    if not request.cookies.get("user") or not request.cookies.get("flow"):
        return JSONResponse(content={"status": "Error: User Not Logged In"}, status_code=200)

    # Reload form configs:
    form_config = find_config()

    # Load tfvars initial files
    tf_json = find_config(extension=".orig.tfvars.json")

    # Create a map based on str maps in the form config files
    maps = {}
    for _, config_doc in form_config.items():
        for _, config in config_doc.items():
            if "str_maps" in config:
                for strm, smap in config["str_maps"].items():
                    maps[strm] = form_values[smap]

    # Evaluate maps across loaded jsons
    for f_name, doc in tf_json.items():
        temp_dump = json.dumps(doc)
        for strm, smap in maps.items():
            temp_dump = temp_dump.replace("{" + strm + "}", smap)
        tf_json[f_name] = json.loads(temp_dump)

    # Process all form keys:
    form_dump = str(json.dumps(form_values))
    for key, smap in maps.items():
        form_dump = form_dump.replace("{" + key + "}", smap)
    form_values = json.loads(form_dump)

    # Write the values to the correct locations in the memory loaded json files
    for key, value in form_values.items():
        if "listinput:" in key:
            value = value.split("\n")
            key = key.replace("listinput:", "")
        for _, doc in tf_json.items():
            # Process a list type value
            dotted_write(key, value, doc)

    # Loop all open TF documents and write them out
    for f_name, doc in tf_json.items():
        json.dump(doc, open(os.path.join(os.getcwd(), "config_output", os.path.basename(f_name)), "w+"))

    # set terraform vars paths
    config_output_dir = os.path.join(os.getcwd(), "config_output")
    global_vars = os.path.join(config_output_dir, "globals.tfvars.json")
    saca_vars = os.path.join(config_output_dir, "saca-hub.tfvars.json")
    tier0_vars = os.path.join(config_output_dir, "tier-0.tfvars.json")
    tier1_vars = os.path.join(config_output_dir, "tier-1.tfvars.json")
    tier2_vars = os.path.join(config_output_dir, "tier-2.tfvars.json")

    # get service principal to execute terraform
    if keyVaultName:
        sp_id = secret_client.get_secret("serviceprincipal-clientid").value
        sp_pwd = secret_client.get_secret("serviceprincipal-pwd").value
    else:
        sp_id = os.getenv("MLZCLIENTID", "NotSet")
        sp_pwd = os.getenv("MLZCLIENTSECRET", "NotSet")

    # write a command to write mlz config:
    src_dir = os.path.dirname(os.getcwd())
    generate_config_executable = os.path.join(src_dir, "scripts", "config", "generate_config_file.sh")
    os.chmod(generate_config_executable, 0o755)

    mlz_config_path = os.path.join(src_dir, "mlz_tf_cfg.var")

    generate_config_args = []
    generate_config_args.append('--file ' + mlz_config_path)
    generate_config_args.append('--tf-env ' + os.getenv("TF_ENV"))
    generate_config_args.append('--metadatahost ' + os.getenv("MLZ_METADATAHOST"))
    generate_config_args.append('--mlz-env-name ' + os.getenv("MLZ_ENV"))
    generate_config_args.append('--location ' + os.getenv("MLZ_LOCATION"))
    generate_config_args.append('--config-sub-id ' + os.getenv("SUBSCRIPTION_ID"))
    generate_config_args.append('--tenant-id ' + os.getenv("TENANT_ID"))
    generate_config_args.append('--hub-sub-id ' + form_values["saca_subid"])
    generate_config_args.append('--tier0-sub-id ' + form_values["tier0_subid"])
    generate_config_args.append('--tier1-sub-id ' + form_values["tier1_subid"])
    generate_config_args.append('--tier2-sub-id ' + form_values["tier2_subid"])

    generate_config_command = "{} {}".format(generate_config_executable, ' '.join(generate_config_args))

    # write a command to execute front_wrapper.sh:
    wrapper_executable = os.path.join(src_dir, "build", "front_wrapper.sh")
    os.chmod(wrapper_executable, 0o755)

    wrapper_command = "{} {} {} {} {} {} {} y {} {}".format(
        wrapper_executable,
        mlz_config_path,
        global_vars,
        saca_vars,
        tier0_vars,
        tier1_vars,
        tier2_vars,
        sp_id,
        sp_pwd)

    with open(exec_output, "w+") as out:
        generate_mlz_config = await asyncio.create_subprocess_exec(*generate_config_command.split(), stderr=out, stdout=out)
        # This capture is setting to a dead object.  If we want to do work with the process in the future
        # we have to do it here.
        await generate_mlz_config.wait()
        _ = await asyncio.create_subprocess_exec(*wrapper_command.split(), stderr=out, stdout=out)

    return JSONResponse(content={"status": "success"}, status_code=200)


# Execute a poll for the contents of a specific job,  logs from terraform execution will be stored as text with
# a job key ast he file name?
@app.get("/poll")
async def poll_results():
    """
    Pol results is an async definition used by the /poll API query to return the results of the exec file

    :return: will return the current contents of the results text file
    """
    try:
        with open(exec_output, "r") as res:
            return JSONResponse(res.read(), status_code=200)
    except:
        return JSONResponse({"results": "No content for that job_num"}, status_code=200)


# Primary entry for unvicorn
# TODO: Replace with docker FlaskAPI Base image later
if __name__ == "__main__":
    port = 80
    if len(sys.argv) > 1:
        port = int(sys.argv[1])
    uvicorn.run(app, host='0.0.0.0', port=port, debug=True)
