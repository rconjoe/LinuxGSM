#!/bin/bash
# LinuxGSM command_mods_uninstall.sh module
# Author: Daniel Gibbs
# Contributors: https://linuxgsm.com/contrib
# Website: https://linuxgsm.com
# Description: Uninstall mods along with mods_list.sh and mods_core.sh.

commandname="MODS-REMOVE"
commandaction="Removing Mods"
moduleselfname="$(basename "$(readlink -f "${BASH_SOURCE[0]}")")"
fn_firstcommand_set

check.sh
mods_core.sh
fn_mods_check_installed

fn_print_header
echo -e "Remove addons/mods"
fn_messages_separator

# Displays list of installed mods.
# Generates list to display to user.
fn_mods_installed_list
for ((mlindex = 0; mlindex < ${#installedmodslist[@]}; mlindex++)); do
	# Current mod is the "mlindex" value of the array we are going through.
	currentmod="${installedmodslist[mlindex]}"
	# Get mod info.
	fn_mod_get_info
	# Display mod info to the user.
	echo -e "${red}${modcommand}${default} - ${modprettyname} - ${moddescription}"
done

echo -e ""
# Keep prompting as long as the user input doesn't correspond to an available mod.
while [[ ! " ${installedmodslist[@]} " =~ " ${usermodselect} " ]]; do
	echo -en "Enter an ${cyan}addon/mod${default} to ${red}remove${default} (or exit to abort): "
	read -r usermodselect
	# Exit if user says exit or abort.
	if [ "${usermodselect}" == "exit" ] || [ "${usermodselect}" == "abort" ]; then
		core_exit.sh
	# Supplementary output upon invalid user input.
	elif [[ ! " ${availablemodscommands[@]} " =~ " ${usermodselect} " ]]; then
		fn_print_error2_nl "${usermodselect} is not a valid addon/mod."
	fi
done

fn_print_warning_nl "You are about to remove ${cyan}${usermodselect}${default}."
echo -e " * Any custom files/configuration will be removed."
if ! fn_prompt_yn "Continue?" Y; then
	core_exit.sh
fi

currentmod="${usermodselect}"
fn_mod_get_info
fn_check_mod_files_list

# Uninstall the mod.
fn_script_log_info "Removing ${modsfilelistsize} files from ${modprettyname}"
echo -e "removing ${modprettyname}"
echo -e "* ${modsfilelistsize} files to be removed"
echo -e "* location: ${modinstalldir}"
fn_sleep_time_1
# Go through every file and remove it.
modfileline="1"
tput sc
while [ "${modfileline}" -le "${modsfilelistsize}" ]; do
	# Current line defines current file to remove.
	currentfileremove=$(sed "${modfileline}q;d" "${modsdir}/${modcommand}-files.txt")
	# If file or directory exists, then remove it.

	if [ -f "${modinstalldir}/${currentfileremove}" ] || [ -d "${modinstalldir}/${currentfileremove}" ]; then
		rm -rf "${modinstalldir:?}/${currentfileremove:?}"
		exitcode=$?
		if [ "${exitcode}" -ne 0 ]; then
			fn_script_log_fail "Removing ${modinstalldir}/${currentfileremove}"
			break
		else
			fn_script_log_pass "Removing ${modinstalldir}/${currentfileremove}"
		fi
	fi
	tput rc
	tput el
	echo -e "removing ${modprettyname} ${modfileline} / ${modsfilelistsize} : ${currentfileremove}..."
	((modfileline++))
done

# Added logic not to fail since removing game specific mods (amxmodxcs) removes files that will
# not be found when removing the base (amxmodx) mod
if [ "${modcommand}" != "amxmodx" ]; then
	if [ "${exitcode}" -ne 0 ]; then
		fn_print_fail_eol_nl
		core_exit.sh
	else
		fn_print_ok_eol_nl
	fi
else
	fn_print_ok_eol_nl
fi

# Remove file list.
echo -en "removing ${modcommand}-files.txt..."
fn_sleep_time_1
rm -rf "${modsdir:?}/${modcommand}-files.txt"
exitcode=$?
if [ "${exitcode}" -ne 0 ]; then
	fn_script_log_fail "Removing ${modsdir}/${modcommand}-files.txt"
	fn_print_fail_eol_nl
	core_exit.sh
else
	fn_script_log_pass "Removing ${modsdir}/${modcommand}-files.txt"
	fn_print_ok_eol_nl
fi

# Remove mods from installed mods list.
echo -en "removing ${modcommand} from ${modsinstalledlist}..."
fn_sleep_time_1

sed -i "/^${modcommand}$/d" "${modsinstalledlistfullpath}"
exitcode=$?
if [ "${exitcode}" -ne 0 ]; then
	fn_script_log_fail "Removing ${modcommand} from ${modsinstalledlist}"
	fn_print_fail_eol_nl
	core_exit.sh
else
	fn_script_log_pass "Removing ${modcommand} from ${modsinstalledlist}"
	fn_print_ok_eol_nl
fi

# Oxide fix
# Oxide replaces server files, so a validate is required after uninstall.
if [ "${engine}" == "unity3d" ] && [[ "${modprettyname}" == *"Oxide"* ]]; then
	fn_print_information_nl "Validating to restore original ${gamename} files replaced by Oxide"
	fn_script_log "Validating to restore original ${gamename} files replaced by Oxide"
	exitbypass=1
	command_validate.sh
	fn_firstcommand_reset
	unset exitbypass
fi

# Remove/modify existing liblist.gam file for Metamod
if [ "${modcommand}" == "metamod" ]; then
	fn_mod_remove_liblist_gam_file
fi

# Remove/modify plugins.ini file for AMX Mod X
if [ "${modcommand}" == "amxmodx" ]; then
	fn_mod_remove_amxmodx_file
fi

# Remove metamod line from gameinfo.gi when uninstalling Metamod: Source 2
if [ "${modcommand}" == "metamodsource2" ]; then
	fn_mod_remove_gameinfo_gi_file
fi

echo -e "${modprettyname} removed"
fn_script_log "${modprettyname} removed"

core_exit.sh
