#!/bin/sh
# only processes a single environment as the placeholder is not preserved

# RHSSO-2211 Import common RH-SSO global variables & functions
source "${JBOSS_HOME}/bin/launch/sso-rcfile-definitions.sh"

function prepareEnv() {
  unset PORT_OFFSET
}

function configure() {
  configure_port_offset
}

function configureEnv() {
  configure
}

function configure_port_offset() {
  if [ -n "${PORT_OFFSET}" ]; then
    # There is no marker for this one, so look for 'port-offset="0"' to decide on xml vs cli
    local mode
    getConfigurationMode "port-offset=\"0\"" "mode"

    if [ "${mode}" = "xml" ]; then
      # RHSSO-2017 Escape possible ampersand and semicolong characters
      # which are interpolated when used in sed righ-hand side expression
      PORT_OFFSET=$(escape_sed_rhs_interpolated_characters "${PORT_OFFSET}")
      # EOF RHSSO-2017 correction
      # CIAM-1394 correction
      sed -i "s${AUS}port-offset=\"0\"${AUS}port-offset=\"${PORT_OFFSET}\"${AUS}g" "$CONFIG_FILE"
      # EOF CIAM-1394 correction
    elif [ "${mode}" = "cli" ]; then

      local cli="
        if (result != 0 && result != ${PORT_OFFSET}) of /socket-binding-group=standard-sockets:read-attribute(name=port-offset, resolve-expressions=true)
            echo You specified PORT_OFFSET=${PORT_OFFSET} while the base configuration\'s value for the port-offset resolves to a different non-zero value. ${PORT_OFFSET} will be used as the port offset. >> \${warning_file}
        end-if
        /socket-binding-group=standard-sockets:write-attribute(name=port-offset, value="${PORT_OFFSET}")"

      echo "$cli" >> ${CLI_SCRIPT_FILE}
    fi
  fi
}
