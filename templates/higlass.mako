<%namespace name="ie" file="ie.mako" />

<%
import os
import shutil
import hashlib

# Sets ID and sets up a lot of other variables
ie_request.load_deploy_config()
ie_request.attr.docker_port = 8888
ie_request.attr.import_volume = False

# Define a volume that will be mounted into the container.
# This is a useful way to provide access to large files in the container,
# if the user knows ahead of time that they will need it.

additional_ids = trans.request.params.get('additional_dataset_ids', None)

if not additional_ids:
    additional_ids = str(trans.security.encode_id( hda.id ) )
else:
    additional_ids += "," + trans.security.encode_id( hda.id )

# Launch the IE. This builds and runs the docker command in the background.
ie_request.launch(
    image=trans.request.params.get('image_tag', None),
    additional_ids=additional_ids if ie_request.use_volumes else None,
    env_override={
        'additional_ids': additional_ids if ie_request.use_volumes else None,
    }
)

# Only once the container is launched can we template our URLs. The ie_request
# doesn't have all of the information needed until the container is running.
notebook_access_url = ie_request.url_template('${PROXY_URL}/higlass/')
%>

<html>
<head>
<!-- Loads some necessary javascript libraries. Specifically jquery,
     toastr, and requirejs -->
${ ie.load_default_js() }
</head>
<body>

<script type="text/javascript">
// see $GALAXY_ROOT/config/plugins/interactive_environments/common/templates/ie.mako to learn what this does
${ ie.default_javascript_variables() }
var notebook_login_url = 'unused';
var notebook_access_url = '${ notebook_access_url }';

// Load code with require.js
${ ie.plugin_require_config() }

// Load notebook
// This will load code from static/higlass.js, often used to handle
// things like Login. The load_notebook function will eventually append
// an IFrame to the <div id="main" /> below.
requirejs(['galaxy.interactive_environments', 'plugin/higlass'], function(IES){
    window.IES = IES
    IES.load_when_ready(ie_readiness_url, function(){
        load_notebook(notebook_access_url);
    });
});
</script>
<div id="main" width="100%" height="100%">
</div>
</body>
</html>