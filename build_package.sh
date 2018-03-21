#!/bin/bash

#description	:Helper tools for building Debian packages
#author			:Bober3X
#Last_revised	:2017.10.05
#version		:1.8.7
#===============================================================================

B_APP_S_VERSION="1.8.7";

B_APP_CFG_FILE_NAME="build_config.sh";
B_APP_TMP_FILE_NAME="build_config_tmp.sh";
B_APP_REBUILD="0";
B_APP_DELETE_SRC="1";
B_APP_AUTO_CREATE_FILE="0";
B_APP_DEF_MAINT="John Doe";
B_APP_DEF_EMAIL="maintainer@example.com";

#===============================================================================

if [ "$(id -u)" != "0" ]; then
	echo "This script must be run as root" 1>&2;
	exit 1;
fi;

show_help()
{
	printf "Usage: $(basename "$0") [-hvadr] [-f filename]\n\n\
	-v - Print version information\n\
	-h - Print usage\n\
	-f - [filename] Use this config file\n\
	-a - Generating automatically the configuration files\n\
	-d - Disable build folder delete\n\
	-r - rebuild pckg\n";
}

while getopts "h?vf:ard" opt; do
	case "$opt" in
		h|\?)
			show_help;
			exit 0;
		;;
		v)
			echo "${B_APP_S_VERSION}";
			exit 0;
		;;
		a)
			B_APP_AUTO_CREATE_FILE="1";
		;;
		d)
			B_APP_DELETE_SRC="0";
		;;
		r)
			B_APP_REBUILD="1";
		;;
		f)
			if [ `echo "${OPTARG}" | egrep ".*\.sh$"` ]; then
				B_APP_CFG_FILE_NAME="${OPTARG}";
				B_APP_TMP_FILE_NAME=`echo "${OPTARG}" | sed 's/\.sh/_tmp\.sh/'`;
			else
				echo "config file must ends with \".sh\"";
				exit 1;
			fi;
		;;
	esac;
done;

B_APP_ROOT_PATH=$(cd $(dirname $0) && pwd);

B_APP_CFG_FILE="${B_APP_ROOT_PATH}"/"${B_APP_CFG_FILE_NAME}";
B_APP_TMP_FILE="${B_APP_ROOT_PATH}"/"${B_APP_TMP_FILE_NAME}";

B_APP_BDATE=`date +%Y-%m-%d_%H.%M.%S`;

B_APP_BLD_VER="1";
B_APP_DEB_DIR="${B_APP_ROOT_PATH}"/"${B_APP_BDATE}"/DEB;

if [ -f "${B_APP_TMP_FILE}" ]; then
	. "${B_APP_TMP_FILE}";
	let "B_APP_BLD_VER = B_APP_BLD_VER + 1";

	if [ "${B_APP_REBUILD}" == "0" ]; then
		B_APP_BDATE=`date +%Y-%m-%d_%H.%M.%S`;
	fi;
fi;

printf "B_APP_BLD_VER=\""${B_APP_BLD_VER}"\";\nB_APP_BDATE=\""${B_APP_BDATE}"\";\n" > "${B_APP_TMP_FILE}";

B_APP_WRK_DIR="${B_APP_ROOT_PATH}"/"${B_APP_BDATE}";
B_APP_DEB_DIR="${B_APP_WRK_DIR}"/DEB;

app_get_last_pckg_ver()
{
	if ( `apt-cache show "${1}" >/dev/null 2>/dev/null` ); then
		V=`apt-cache show "${1}" | grep "Version:" | sed 's/Version: //'`;
		printf "${1} (>= %s)\n" ${V};
	else
		echo "Error: Package \""${1}"\" not found...";
		exit 1;
	fi;
};

app_pre_test_config()
{
	echo "### PRE_TEST_CONFIG ###";

	if [[ ! "$(declare -Ff "APP_USER_PRE_TEST_CONFIG")" ]]; then
		return 0;
	else
		APP_USER_PRE_TEST_CONFIG;
		return $1;
	fi;
}

app_test_config()
{
	echo "#### TEST CONFIG ####";

	for c in "find" "file" "sed" "awk" "bunzip2" "let"; do
		command -v "${c}" >/dev/null 2>&1 || \
			{ echo "This require \""${c}"\" but it's not installed. Aborting." >&2; exit 1; }
	done;

	if [ ! -f "${B_APP_CFG_FILE}" ]; then
		echo "Error: File \""${B_APP_CFG_FILE}"\" does not exist...";

		if [ "${B_APP_AUTO_CREATE_FILE}" = "1" ]; then
			echo "Create File \""${B_APP_CFG_FILE}"\"...";
			printf "APP_PCKG_MAINTAINER=\"%s <%s>\";\n\nAPP_TEST_BUILD=\"false\";\n" "${B_APP_DEF_MAINT}" "${B_APP_DEF_EMAIL}" > "${B_APP_CFG_FILE}";
		else
			return 1;
		fi;
	fi;

	. ${B_APP_CFG_FILE};

	B_APP_NVAR_ERR="	APP_SRC_ARCH!@It is archive file. Set it, for example, like this: APP_SRC_ARCH=\"\${B_APP_ROOT_PATH}/dovecot-2.2.18.tar.gz\";
						APP_DEB_PCKG!@It is list of packages to build
						APP_VERSION!@It use for string of version in package, if is not specified separately. Example: APP_VERSION=\"1:2.2.16-debian6+\${B_APP_BLD_VER}\";
						APP_PCKG_MAINTAINER!@Set it, for example, like this: APP_PCKG_MAINTAINER=\"Unknown <unknown@example.ru>\";
						APP_SRC_DIR!@Set it, for example, like this: APP_SRC_DIR=\"\"\${B_APP_ROOT_PATH}\"/\"\${B_APP_BDATE}\"/php-5.4.38\";";

	B_APP_NVAR_WRN="	APP_HOMEPAGE!@
						APP_TEST_BUILD!@Set it like this: APP_TEST_BUILD=\"false\";
						APP_CFLAGS!@
						APP_CFG_OPTS!@";

	IFS=$'\n';

	for nvar in ${B_APP_NVAR_ERR}; do
		var1=`echo "${nvar}" | awk -F "!@" '{print $1}' | sed 's/[\t ]//g'`;
		var2=`echo "${nvar}" | awk -F "!@" '{print $2}'`;
		eval var=\${`echo "${var1}"`};
		if [ -z "${var}" ]; then
			echo "Error: Parameter \""${var1}"\" does not set...";
			echo "${var2}";
			return 1;
		fi;
	done;

	app_pre_test_config;

	if [ ! -f "${APP_SRC_ARCH}" ]; then
		if [ "${APP_SRC_ARCH}" != "none" ]; then
			echo "Error: Does not exist file '${APP_SRC_ARCH}'";
			return 1;
		fi;
	fi;

	for nvar in ${B_APP_NVAR_WRN}; do
		var1=`echo "${nvar}" | awk -F "!@" '{print $1}' | sed 's/[\t ]//g'`;
		var2=`echo "${nvar}" | awk -F "!@" '{print $2}'`;
		eval var=\${`echo "${var1}"`};
		if [ -z "${var}" ]; then
			echo "Warning: Parameter \""${var1}"\" does not set...";
			if [ -n "${var2}" ]; then echo "Description: ${var2}"; fi;
		fi;
	done;

	B_APP_PCKG_NVAR_WRN="	VERSION@!
							CONFFILES@!
							DEPENDS@!
							PREDEPENDS@!
							SOURCE@!
							SECTION@!
							REPLACES@!
							BREAKS@!
							PRIORITY@!
							TRIGGERS@!
							SUGGESTS@!
							PROVIDES@!
							RECOMMENDS@!
							CONFLICTS@!";

	B_APP_PCKG_NVAR_ERR="	DESCRIPTION@!
							ARCH@!";

	IFS=" ";
	for pckg in `echo ${APP_DEB_PCKG} | sed ':a;N;$!ba;s/\n/ /g' | sed 's/[\t]//g' | sed 's/\ \+/ /g'`; do
		rminst_file=`echo "${pckg}" | sed 's/[-\.]/_/g' | sed 's/[\t ]//g'`;

		if [ ! -f "${B_APP_ROOT_PATH}"/build_config_"${rminst_file}".sh ]; then
			echo "Error: Does not exist file \""${B_APP_ROOT_PATH}"/build_config_"${rminst_file}".sh\"";
			if [ "${B_APP_AUTO_CREATE_FILE}" = "1" ]; then
				echo "Create file \""${B_APP_ROOT_PATH}"/build_config_"${rminst_file}".sh\"...";
				printf "APP_DEB_PCKG_"${rminst_file}"_DESCRIPTION=\"change me\";\n\nAPP_DEB_PCKG_"${rminst_file}"_ARCH=\"amd64\";\n\n"${rminst_file}"()\n{\n	return 0;\n}\n" > "${B_APP_ROOT_PATH}"/build_config_"${rminst_file}".sh;
			else
				return 1;
			fi;
		fi;

		. "${B_APP_ROOT_PATH}"/build_config_"${rminst_file}".sh;

		IFS=$'\n';

		for nvar in ${B_APP_PCKG_NVAR_WRN}; do
			var1=`echo "${nvar}" | awk -F "@!" '{print $1}' | sed 's/[\t ]//g'`;
			var2=`echo "${nvar}" | awk -F "@!" '{print $2}'`;
			eval var=\${`echo APP_DEB_PCKG_"${rminst_file}"_"${var1}"`};

			if [ -z "${var}" ]; then
				echo "Warning: argument \"APP_DEB_PCKG_"${rminst_file}"_"${var1}"\" does not set";
				if [ -n "${var2}" ]; then echo "Description: ${var2}"; fi;
			fi;
		done;

		for nvar in ${B_APP_PCKG_NVAR_ERR}; do
			var1=`echo "${nvar}" | awk -F "@!" '{print $1}' | sed 's/[\t ]//g'`;
			var2=`echo "${nvar}" | awk -F "@!" '{print $2}'`;
			eval var=\${`echo APP_DEB_PCKG_"${rminst_file}"_"${var1}"`};

			if [ -z "${var}" ]; then
				echo "Error: argument \"APP_DEB_PCKG_"${rminst_file}"_"${var1}"\" does not set";
				if [ -n "${var2}" ]; then echo "Description: ${var2}"; fi;
				return 1;
			fi;
		done;

		if [[ ! "$(declare -Ff "${rminst_file}")" ]]; then
			echo "Error: function \""${rminst_file}"\" does not exist...";
			return 1;
		fi;

		B_APP_PCKG_NFILE_WRN=".postinst.sh .postrm.sh .preinst.sh .prerm.sh .dirs .links";

		IFS=" ";

		for nfile in ${B_APP_PCKG_NFILE_WRN}; do
			if [ ! -f "${B_APP_ROOT_PATH}"/build_config_"${rminst_file}""${nfile}" ]; then
				echo "Warning: file \""${B_APP_ROOT_PATH}"/build_config_"${rminst_file}""${nfile}"\" does not exist...";
			fi;
		done;
	done;

	return 0;
}

app_checking_the_existence_of_the_required_packages()
{
	echo "CHECKING THE EXISTENCE OF THE REQUIRED PACKAGES";

	if [ -n "${APP_REQ_PCKGAV}" ]; then
		B_APP_PCKGAV=`echo ${APP_REQ_PCKGAV} | sed ':a;N;$!ba;s/\n/ /g'`;

		IFS=" ";

		for pckgav in ${B_APP_PCKGAV}; do
			pckg_name=`echo "${pckgav}" | awk -F "@" '{print $1}'`;

			if [ "`dpkg -l | egrep  "^ii[ ]+"${pckg_name}" " > /dev/null && echo "OK"`" != "OK" ]; then
				echo "Package \""${pckg_name}"\" does not installed...";
				return 1;
			fi;
		done;
	fi;

	return 0;
}

app_unpack_archive()
{
	echo "### UNPACK_ARCHIVE ###";

	mkdir "${B_APP_WRK_DIR}";

	if [ -f "${APP_SRC_ARCH}" ]; then
		if [[ "${APP_SRC_ARCH}" =~ .tar.bz2$ ]]; then
			bunzip2 -dc "${APP_SRC_ARCH}" | tar -xf - -C "${B_APP_WRK_DIR}" && return 0;
		else
			if [[ "${APP_SRC_ARCH}" =~ .tar.gz$ ]] || [[ "${APP_SRC_ARCH}" =~ .tar.Z$ ]]; then
				tar -zxf "${APP_SRC_ARCH}" -C "${B_APP_WRK_DIR}" && return 0;
			else
				if [[ "${APP_SRC_ARCH}" =~ .zip$ ]]; then
					unzip -q "${APP_SRC_ARCH}" -d "${B_APP_WRK_DIR}" && return 0;
				else
					if [[ "${APP_SRC_ARCH}" =~ .tar.xz$ ]]; then
						tar -xf "${APP_SRC_ARCH}" -C "${B_APP_WRK_DIR}" && return 0;
					else
						echo "Error: Unknown archive type...";
					fi;
				fi;
			fi;
		fi;
	else
		if [ "${APP_SRC_ARCH}" != "none" ]; then
			echo "Error: file \""${APP_SRC_ARCH}"\" not found...";
		else
			return 0;
		fi;
	fi;

	return 1;
}

app_post_unpack_archive()
{
	echo "### POST_UNPACK_ARCHIVE ###";

	if [[ "$(declare -Ff "APP_DEB_PCKG_POST_UNPACK")" ]]; then
		if ! APP_DEB_PCKG_POST_UNPACK; then
			return 1;
		fi;
	fi;

	for pckg in ${APP_DEB_PCKG};do
		if [[ "$(declare -Ff "APP_DEB_PCKG_""${pckg}""_POST_UNPACK")" ]]; then
			if ! APP_DEB_PCKG_${pckg}_POST_UNPACK; then
				return 1;
			fi;
		fi;
	done;

	return 0;
}

app_configure()
{
	echo "### APP CONFIGURE ###";

	RCODE=0;

	if [ -d "${APP_SRC_DIR}" ]; then
		cd "${APP_SRC_DIR}";

		CFLAGS="${APP_CFLAGS}";
		export CFLAGS;

		if [ "${APP_AUTOGENSH}" != "false" ]; then
			if [ -f "./autogen.sh" ]; then
				echo ./autogen.sh "${APP_ACFG_OPTS}";
				./autogen.sh ${APP_ACFG_OPTS};

				if [ ${?} -ne 0 ]; then
					echo "Error: autogen.sh return false...";
					RCODE=1;
				fi;
			else
				echo "Warning: file \""${APP_SRC_DIR}"/autogen.sh\" does not exist...";
			fi;
		fi;

		if [[ "${RCODE}" -eq 0 ]]; then
			if [ "${APP_RUNCONFIGURE}" != "false" ]; then
				if [ -f ""${APP_SRC_DIR}"/configure" ]; then
					echo "${APP_SRC_DIR}"/configure "${APP_CFG_OPTS}";
					"${APP_SRC_DIR}"/configure ${APP_CFG_OPTS};

					if [[ "${?}" -ne 0 ]]; then
						echo "Error: configure return false...";
						RCODE=1;
					fi;
				else
					echo "Warning: file \""${APP_SRC_DIR}"/configure\" does not exist...";
				fi;
			fi;
		fi;
	else
		if [ "${APP_SRC_DIR}" != "none" ]; then
			echo "Error: dir \""${APP_SRC_DIR}"\" does not exist...";
			RCODE=1;
		else
			RCODE=0;
		fi;
	fi;

	cd "${B_APP_ROOT_PATH}";

	return ${RCODE};
}

app_build_app()
{
	echo "### APP BUILD ###";

	if [ "${APP_SRC_DIR}" = "none" ]; then return 0; fi;

	if [[ ! "$(declare -Ff "APP_USER_BUILD")" ]]; then
		cd "${APP_SRC_DIR}";

		CFLAGS="${APP_CFLAGS}";
		export CFLAGS;

		if make; then
			cd "${B_APP_ROOT_PATH}";
			unset CFLAGS;
			return 0;
		fi;

		unset CFLAGS;
	else
		echo "### APP_USER_BUILD ###";
		APP_USER_BUILD;
		return $1;
	fi;

	return 1;
}

app_post_build_app()
{
	echo "### APP POST BUILD ###";

	if [[ ! "$(declare -Ff "APP_POST_BUILD")" ]]; then
		return 0;
	else
		APP_POST_BUILD;
		return $1;
	fi;

	return 1;
}

app_post_build_pckg()
{
	echo "### APP POST BUILD PCKG ###";

	if [[ ! "$(declare -Ff "APP_POST_BUILD_PCKG")" ]]; then
		return 0;
	else
		APP_POST_BUILD_PCKG;
		return $1;
	fi;

	return 1;
}

app_test_build_app()
{
	if [ -n "${APP_TEST_BUILD}" ]; then
		if [ "${APP_TEST_BUILD}" != "false" ]; then
			if [ "${APP_TEST_BUILD}" != "0" ]; then
				cd "${APP_SRC_DIR}";

				if make test; then
					cd "${B_APP_ROOT_PATH}";
					return 0;
				fi;

				return 1;
			fi;
		fi;
	fi;

	return 0;
}

app_clean()
{
	echo "### APP CLEAN ###";

	rm -rf "${B_APP_DEB_DIR}";

	return 0
}

app_build_pckg()
{
	echo "### BUILD PCKG ###";

	mkdir "${B_APP_DEB_DIR}";

	IFS=" ";
	for pckg in `echo ${APP_DEB_PCKG} | sed ':a;N;$!ba;s/\n/ /g' | sed 's/[\t]//g' | sed 's/\ \+/ /g'`; do
		echo "Build \""${pckg}"\" package";

		#rminst_file=`echo "${pckg}" | sed 's/[-\.]/_/g' | sed 's/[\t ]//g'`;
		rminst_file=`echo "${pckg}" | sed 's/[-\.]/_/g'`;

		PCKG_DIR="${B_APP_DEB_DIR}"/"${pckg}";

		mkdir "${B_APP_DEB_DIR}"/"${pckg}" && mkdir "${B_APP_DEB_DIR}"/"${pckg}"/DEBIAN;

		if [ -f "${B_APP_ROOT_PATH}"/build_config_"${rminst_file}".dirs ]; then
			IFS=$'\n';
			for dir in `cat "${B_APP_ROOT_PATH}"/build_config_"${rminst_file}".dirs`; do
				mkdir -p "${B_APP_DEB_DIR}"/"${pckg}"/"${dir}";
			done;
		fi;

		"${rminst_file}" "${B_APP_DEB_DIR}"/"${pckg}" "${B_APP_ROOT_PATH}";
		cd "${B_APP_ROOT_PATH}";

		if [ -f "${B_APP_ROOT_PATH}"/build_config_"${rminst_file}".links ]; then
			IFS=$'\n';
			for link in `cat "${B_APP_ROOT_PATH}"/build_config_"${rminst_file}".links`; do
				file1=`echo "${link}" | awk '{print $1}'`;
				file2=`echo "${link}" | awk '{print $2}'`;
				if [ "${file1%/*}" = "${file2%/*}" ]; then
					#echo "${file1##*/}";
					ln -s ./"${file1##*/}" "${B_APP_DEB_DIR}"/"${pckg}""${file2}";
				else
					ln -s "${file1}" "${B_APP_DEB_DIR}"/"${pckg}""${file2}";
				fi;
				#ln -s "${file1}" "${B_APP_DEB_DIR}"/"${pckg}""${file2}";
				#ln -r -s -t "${B_APP_DEB_DIR}"/"${pckg}"/ "${file1}";
				#ln -s "${B_APP_DEB_DIR}"/"${pckg}"/"${file1}" "${file2}";
			done;
		fi;

		echo "Package: "${pckg}"" > "${B_APP_DEB_DIR}"/"${pckg}"/DEBIAN/control;

		eval PCKG_VERSION=\${`echo APP_DEB_PCKG_"${rminst_file}"_VERSION`};
		if [ -z "${PCKG_VERSION}" ]; then
			PCKG_VERSION="${APP_VERSION}";
		fi;
		echo "Version: "${PCKG_VERSION}"" >> "${B_APP_DEB_DIR}"/"${pckg}"/DEBIAN/control;

		echo "Maintainer: "${APP_PCKG_MAINTAINER}"" >> "${B_APP_DEB_DIR}"/"${pckg}"/DEBIAN/control;

		if [ -n "${APP_HOMEPAGE}" ]; then
			echo "Homepage: "${APP_HOMEPAGE}"" >> "${B_APP_DEB_DIR}"/"${pckg}"/DEBIAN/control;
		fi;

		PCKG_SIZE=`find "${B_APP_DEB_DIR}"/"${pckg}" -maxdepth 1 -mindepth 1 -type d \
						-not \( -path "${B_APP_DEB_DIR}"/"${pckg}"/DEBIAN \) -exec du -bsx {} \; | \
							awk 'BEGIN{S=0}{S=S+$1}END{printf "%.0f\n", S/1024}'`;
		echo "Installed-Size: ${PCKG_SIZE}" >> "${B_APP_DEB_DIR}"/"${pckg}"/DEBIAN/control;

		eval PCKG_ARCH=\${`echo APP_DEB_PCKG_"${rminst_file}"_ARCH`};
		if [ -n "${PCKG_ARCH}" ]; then
			echo "Architecture: "${PCKG_ARCH}"" >> "${B_APP_DEB_DIR}"/"${pckg}"/DEBIAN/control;
		fi;

		PCKG_VAR="	SOURCE!@Source
					PREDEPENDS!@Pre-Depends
					DEPENDS!@Depends
					RECOMMENDS!@Recommends
					BREAKS!@Breaks
					REPLACES!@Replaces
					CONFLICTS!@Conflicts
					PROVIDES!@Provides
					SECTION!@Section
					PRIORITY!@Priority
					SUGGESTS!@Suggests
					MULTIARCH!@Multi-Arch";
		IFS=$'\n';
		for nvar in ${PCKG_VAR}; do
			var1=`echo "${nvar}" | awk -F "!@" '{print $1}' | sed 's/[\t ]//g'`;
			var2=`echo "${nvar}" | awk -F "!@" '{print $2}' | sed 's/[\t ]//g'`;
			eval var=\${`echo APP_DEB_PCKG_"${rminst_file}"_"${var1}"`};
			if [ -n "${var}" ]; then
				echo ""${var2}": "${var}"" >> "${B_APP_DEB_DIR}"/"${pckg}"/DEBIAN/control;
			fi;
		done;
		IFS=" ";

		eval var=\${`echo APP_DEB_PCKG_"${rminst_file}"_DESCRIPTION`};
		if [ -n "${var}" ]; then
			echo Description: ${var} >> "${B_APP_DEB_DIR}"/"${pckg}"/DEBIAN/control;
		fi;

		eval var=\${`echo APP_DEB_PCKG_"${rminst_file}"_TRIGGERS`};
		if [ -n "${var}" ]; then
			echo "${var}" > "${B_APP_DEB_DIR}"/"${pckg}"/DEBIAN/triggers;
			chmod 444 "${B_APP_DEB_DIR}"/"${pckg}"/DEBIAN/triggers;
		fi;

		eval var=\${`echo APP_DEB_PCKG_"${rminst_file}"_CONFFILES`};
		if [ -n "${var}" ]; then
			touch "${B_APP_DEB_DIR}"/"${pckg}"/DEBIAN/conffiles;
			IFS=$'\n';
			for conffile in ${var}; do
				echo ${conffile} >> "${B_APP_DEB_DIR}"/"${pckg}"/DEBIAN/conffiles;
			done;
		fi;

		POSTPREFILE="preinst postinst prerm postrm";
		IFS=" ";
		for file in ${POSTPREFILE}; do
			varfile=`echo build_config_"${rminst_file}"."${file}".sh`;
			if [ -f "${varfile}" ]; then
				cp "${varfile}" "${B_APP_DEB_DIR}"/"${pckg}"/DEBIAN/"${file}";
				chmod 555 "${B_APP_DEB_DIR}"/"${pckg}"/DEBIAN/"${file}";
			fi;
		done;

		if [ -f "${PCKG_DIR}"/DEBIAN/conffiles ]; then
			echo "find ""${PCKG_DIR}""/ -type f -not \( -path \""${PCKG_DIR}"/DEBIAN/*\" \) -not \( "`cat "${PCKG_DIR}"/DEBIAN/conffiles | awk '{print "-path \"'"${PCKG_DIR}"'" $1 "\"" }' | sed ':a;N;$!ba;s/\n/ -o /g'`" \) -exec md5sum {} \; | awk '{sub(\""${PCKG_DIR}"/\",\"\",\$2);print \$1\" \"\$2}' > "${PCKG_DIR}"/DEBIAN/md5sums" > rr.sh;
		else
			echo "find ""${PCKG_DIR}""/ -type f -not \( -path \""${PCKG_DIR}"/DEBIAN/*\" \) -exec md5sum {} \; | awk '{sub(\""${PCKG_DIR}"/\",\"\",\$2);print \$1\" \"\$2}' > "${PCKG_DIR}"/DEBIAN/md5sums" > rr.sh;
		fi;

		chmod 555 rr.sh;
		./rr.sh;
		rm ./rr.sh

		dpkg-deb -b "${B_APP_DEB_DIR}"/"${pckg}" "${B_APP_WRK_DIR}"/"${rminst_file}"_"${PCKG_VERSION}"_"${PCKG_ARCH}".deb;
	done;

	return 0;
}

app_strip()
{
	echo "### STRIP ###";

	if [ `echo ""${1}"" | grep ""${B_APP_BDATE}""` ]; then
		IFS=$'\n';
		for file in `find ${1} -type f`; do
			ftype=`file -b "${file}"`;
			if [[ "${ftype}" =~ "ELF 64-bit LSB executable" ]] || \
				[[ "${ftype}" =~ "ELF 32-bit LSB executable" ]] || \
				[[ "${ftype}" =~ "ELF 32-bit LSB shared" ]] || \
				[[ "${ftype}" =~ "ELF 64-bit LSB shared object" ]]; then
				strip "${file}";
			fi;
		done;
	fi;
}

app_set_default_permissions()
{
	echo "### SET DEFAULT PERMISSIONS ###";

	if [ `echo ""${1}"" | grep ""${B_APP_BDATE}""` ]; then
		IFS=$'\n';
		for file in `find ${1} -type f`; do
			chown root:root "${file}";
			ftype=`file -F "@" "${file}" | awk -F "@" '{print $2}'`;

			if [[ "${ftype}" =~ "ELF 64-bit LSB executable" ]] || \
				[[ "${ftype}" =~ "ELF 32-bit LSB executable" ]] || \
				[[ "${ftype}" =~ "Perl script text executable" ]] || \
				[[ "${ftype}" =~ "ASCII text executable" ]]; then
				chmod 555 "${file}";
			else
				chmod 444 "${file}";
			fi;
		done;

		for dir in `find ${1} -type d`; do
			chown root:root "${dir}";
			chmod 755 "${dir}";
		done;
	fi;
}

if [ "${B_APP_REBUILD}" == "0" ]; then
	app_test_config && app_checking_the_existence_of_the_required_packages && \
		app_unpack_archive && app_post_unpack_archive && \
			app_configure && app_build_app && \
				app_post_build_app && app_test_build_app && app_build_pckg && app_post_build_pckg && app_clean;
else
	app_clean && app_test_config && app_post_build_app && app_build_pckg && app_post_build_pckg && app_clean;
fi;

if [ "${B_APP_DELETE_SRC}" == "1" ]; then
	rm -rf "${APP_SRC_DIR}";
fi;
