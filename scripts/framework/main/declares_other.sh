# Global variable declarations unrelated to rollback (By Davy Keppens on 06/10/18)
# Enable/Disable debug by running 'confpieh_ph.sh -p debug -m declares_other.sh'

declare -x PH_SCRIPTS_DIR
declare -x PH_INST_DIR
declare -x PH_BASE_DIR
declare -x PH_BUILD_DIR
declare -x PH_SNAPSHOT_DIR
declare -x PH_MNT_DIR
declare -x PH_CONF_DIR
declare -x PH_MAIN_DIR
declare -x PH_FUNCS_DIR
declare -x PH_TMP_DIR
declare -x PH_FILES_DIR
declare -x PH_MENUS_DIR
declare -x PH_TEMPLATES_DIR
declare -x PH_EXCLUDES_DIR
declare -x PH_VERSION
declare -x PH_DISTRO
declare -x PH_DISTRO_REL
declare -x PH_RUN_USER
declare -x PH_RUN_GROUP
declare -x PH_SUDO
declare -x PH_PI_MODEL
declare -x PH_FILE_SUFFIX
declare -ax PH_SUPPORTED_DISTROS
declare -ax PH_DISTRO_CONFIGS

PH_SCRIPTS_DIR="$(cd "$(dirname "${0}")" && pwd)"
PH_BASE_DIR="${PH_SCRIPTS_DIR%/scripts/framework}"
PH_INST_DIR="${PH_BASE_DIR%/PieHelper}"
PH_USER_SCRIPTS_DIR="${PH_BASE_DIR}/scripts/user-defined"
PH_BUILD_DIR="${PH_BASE_DIR}/builds"
PH_SNAPSHOT_DIR="${PH_BASE_DIR}/snapshots"
PH_MNT_DIR="${PH_BASE_DIR}/mnt"
PH_CONF_DIR="${PH_BASE_DIR}/conf/framework"
PH_USER_CONF_DIR="${PH_BASE_DIR}/conf/user-defined"
PH_MAIN_DIR="${PH_BASE_DIR}/scripts/framework/main"
PH_FUNCS_DIR="${PH_BASE_DIR}/functions/framework"
PH_USER_FUNCS_DIR="${PH_BASE_DIR}/functions/user-defined"
PH_TMP_DIR="${PH_BASE_DIR}/tmp"
PH_FILES_DIR="${PH_BASE_DIR}/files/framework"
PH_USER_FILES_DIR="${PH_BASE_DIR}/files/user-defined"
PH_MENUS_DIR="${PH_FILES_DIR}/menus"
PH_TEMPLATES_DIR="${PH_FILES_DIR}/templates"
PH_EXCLUDES_DIR="${PH_FILES_DIR}/excludes"
PH_VERSION=""
PH_DISTRO=""
PH_DISTRO_REL=""
PH_RUN_USER=""
PH_RUN_GROUP=""
PH_SUDO=""
PH_PI_MODEL=""
