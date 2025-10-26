#!/usr/bin/env python3

import contextlib as __stickytape_contextlib

@__stickytape_contextlib.contextmanager
def __stickytape_temporary_dir():
    import tempfile
    import shutil
    dir_path = tempfile.mkdtemp()
    try:
        yield dir_path
    finally:
        shutil.rmtree(dir_path)

with __stickytape_temporary_dir() as __stickytape_working_dir:
    def __stickytape_write_module(path, contents):
        import os, os.path

        def make_package(path):
            parts = path.split("/")
            partial_path = __stickytape_working_dir
            for part in parts:
                partial_path = os.path.join(partial_path, part)
                if not os.path.exists(partial_path):
                    os.mkdir(partial_path)
                    with open(os.path.join(partial_path, "__init__.py"), "wb") as f:
                        f.write(b"\n")

        make_package(os.path.dirname(path))

        full_path = os.path.join(__stickytape_working_dir, path)
        with open(full_path, "wb") as module_file:
            module_file.write(contents)

    import sys as __stickytape_sys
    __stickytape_sys.path.insert(0, __stickytape_working_dir)

    __stickytape_write_module('installer_helpers.py', b'import os, glob, shlex, subprocess, sys, shutil, re, json\nimport logging\nimport inspect\n\nlogger = logging.getLogger()\n\ndef require_root():\n  \'\'\'\n  Only proceed if sudo or root. If not root or sudo, we are going to fork+exec ourselves\n  via sudo instead.\n  \'\'\'\n  if os.getuid() != 0:\n    logger.info("You need to be root or have sudo to run the installer")\n    logger.info("I will now ask you for your account password.")\n    logger.info("If this doesn\'t work then you probably have a Linux IFFS system,")\n    logger.info("and you have to run this installer as root.")\n\n    toplevel_file = os.path.realpath(inspect.stack()[-1][1])\n    subprocess.call((\'sudo\', toplevel_file))\n    exit(0)\n\ndef normalize_shader_directory_paths(paths):\n  paths = list(filter(not_reactor, paths))\n  paths = [drill_down_to_shaders(d) for d in paths]\n  return paths\n\ndef sw_version_from_path(path_to_shaders_dir):\n  \'\'\'\n  Recover a canonical flame version string (like "2018.0.0") that will correctly\n  sort lexicographically with our required shader version string. We are going to\n  use it to reject shaders from installations into directories with which they\n  are not compatible\n  \'\'\'\n  def get_at(list, index, default=None):\n    return list[index] if max(~index, index) < len(list) else default\n\n  head, tail = os.path.split(path_to_shaders_dir)\n  if not tail:\n    return\n  maybe_match = re.search(\'(20\\d\\d(.+)?)\', tail)\n  if maybe_match:\n    matched_parts = maybe_match.group(0).split(\'.\')\n    major, extension, release = get_at(matched_parts, 0, \'0\'), get_at(matched_parts, 1, \'0\'), get_at(matched_parts, 2, \'0\')\n    return \'.\'.join((major, extension, release))\n  else:\n    return sw_version_from_path(head)\n\ndef drill_down_to_shaders(matchbox_dir):\n  \'\'\'\n  If the given directory contains a subdirectory called "shaders", will return the path\n  to that subdirectory. Else - will return the given directory back.\n  Newer versions put the actual shaders in a subdirectory, so we account for that here.\n  \'\'\'\n  if os.path.isdir(os.path.join(matchbox_dir, "shaders")):\n    return os.path.join(matchbox_dir, "shaders")\n  else:\n    return matchbox_dir\n\ndef not_reactor(path):\n  \'\'\'\n  Remove the background reactor directories since they never get accessed via UI\n  \'\'\'\n  reactor_re = re.compile(r\'backgroundreactor\')\n  return not re.match(reactor_re, path)\n\ndef soft_remove(in_dir, filename):\n  path = os.path.join(in_dir, filename)\n  if os.path.isfile(path):\n    os.remove(path)\n\ndef load_manifest(manifest_path):\n  with open(manifest_path, \'r\') as f:\n    return json.load(f)\n    \ndef soft_mkdir(dir):\n  logger.info("\\t Creating directory %s" % dir)\n  os.makedirs(dir)\n\ndef remove_conflicting_shader_versions(in_dir_path, shader_name):\n  \'\'\'\n  When we install shaders, we might be installing versions which are now multi-pass - whereas\n  the currently installed version is single-pass. If we do that, we will end up with things like\n  "ZZ_Shade.glsl" as well as "ZZ_Shade.1.glsl" and confusion and mayhem will ensue. We have\n  to ensure that if we install shader X, we are only going to have the version of shader X\n  that the installer bundlers installed, and no older version will be in the directory creating\n  possible conflicts and/or confusion. Since we store the shader name on the manifest, we\n  will use it to match \n  \'\'\'\n  for filename in os.listdir(in_dir_path):\n    if filename.startswith(shader_name):\n      logger.debug("Found instaled %s in %s, need to remove it to prevent conflicts with %s we are about to install." % (filename, in_dir_path, shader_name))\n      soft_remove(in_dir_path, filename)\n\ndef soft_copy_file(from_path, to_path):\n  shutil.copyfile(from_path, to_path)\n\ndef ensure_write_privilege(dirpath):\n  if not os.access(dirpath, os.W_OK):\n    logger.error("""\n      We do not have permission to write to the IFFS-controlled directory %s\\n\n      You will need to run this installer as root or via sudo\n      """ % dirpath)\n    exit(1)\n\ndef install_into_dir(dest_path, shader_type, installer_shaders_dir_path, shader_info_dicts):\n  sw_version = sw_version_from_path(dest_path)\n  logger.info("%s (version %s)" % (dest_path, sw_version))\n\n  # Find which matchboxes are usable on this version\n  matches_version = lambda s: s[\'shader_type\'] == shader_type and s[\'required_matchbox_version\'] <= sw_version\n  applicable_matchboxes = list(filter(matches_version, shader_info_dicts))\n  logger.info("%d shaders satisfy version and type, installing." % len(applicable_matchboxes))\n\n  logik_dir = os.path.join(dest_path, \'LOGIK\')\n\n  # Create the LOGIK subdir in the shader directory\n  # if it doesn\'t exist yet\n  if not os.path.isdir(logik_dir):\n    soft_mkdir(logik_dir)\n\n  # Remove shaders that might be conflicting, and install the versions from the current package instead\n  for shader in applicable_matchboxes:\n    logger.debug("Installing %s into %s" % (shader[\'name\'], logik_dir))\n    remove_conflicting_shader_versions(logik_dir, shader[\'name\'])\n    for filename in shader[\'filenames\']:\n      soft_copy_file(os.path.join(installer_shaders_dir_path, filename), os.path.join(logik_dir, filename))\n\n')
    __stickytape_write_module('logging_setup.py', b"import logging, time, inspect, os\n\nlogger = logging.getLogger()\n\nhuman_formatter = logging.Formatter('%(message)s')\nstdio_handler = logging.StreamHandler()\nstdio_handler.setFormatter(human_formatter)\nstdio_handler.setLevel(logging.INFO)\nlogger.addHandler(stdio_handler)\n\n\nlast_stack_item = inspect.stack()[-1][1]\ntoplevel_dir = os.path.dirname(os.path.realpath(last_stack_item))\nlogfile_path = os.path.join(toplevel_dir, 'INSTALL_%s.log' % time.strftime('%Y-%m-%d-%H%M%S'))\nlogfile_handler = logging.FileHandler(logfile_path)\n\nfile_formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')\nlogfile_handler.setFormatter(file_formatter)\nlogfile_handler.setLevel(logging.DEBUG)\nlogger.addHandler(logfile_handler)\n\nlogger.setLevel(logging.DEBUG)")
    #!/usr/bin/env python3
    
    import os, glob, shlex, subprocess, sys, shutil, re, logging
    sys.path.append(os.path.join(os.path.dirname(os.path.abspath(__file__)), 'modules'))
    
    import installer_helpers as logik
    import logging_setup
    
    logger = logging.getLogger()
    logger.info("Shader installer running python %s" % (sys.version))
    
    logik.require_root()
    
    installer_dir = os.path.dirname(os.path.realpath(__file__))
    pkgdir = os.path.join(installer_dir, 'shaders')
    
    logger.info("Loading and parsing manifest...")
    
    manifest_path = os.path.join(installer_dir, 'manifest.json')
    shader_info_dicts = logik.load_manifest(manifest_path)
    
    logger.debug("Loaded %d shaders on the manifest" % len(shader_info_dicts))
    logger.info("Finding installs of IFFS that host shaders...")
    
    # Find all Matchbox directories, both /usr/discreet and /opt/Autodesk
    matchbox_directories = logik.normalize_shader_directory_paths(glob.glob("/opt/Autodesk/*/matchbox") +
      glob.glob("/opt/Autodesk/presets/*/matchbox") +
      glob.glob("/usr/discreet/*/matchbox") +
      glob.glob("/usr/discreet/presets/*/matchbox"))
    lightbox_directories = logik.normalize_shader_directory_paths(glob.glob("/opt/Autodesk/presets/*/action/lightbox") +
      glob.glob("/usr/discreet/presets/*/action/lightbox"))
    
    # Make sure we fail before we try to write
    [logik.ensure_write_privilege(d) for d in matchbox_directories + lightbox_directories]
    
    logger.info("Installing matchboxes:")
    for dest_path in matchbox_directories:
      logik.install_into_dir(dest_path, 'matchbox', pkgdir, shader_info_dicts)
    
    logger.info("Installing lightboxes:")
    for dest_path in lightbox_directories:
      logik.install_into_dir(dest_path, 'lightbox', pkgdir, shader_info_dicts)
    
    logger.info("Installation complete!")
    
    exit(0)
    
    