#!/bin/sh
# filename: buildDaily.sh

             ###################################################
             # Adium clean, update, package, and upload script #
             ###################################################

	# Credits:

	     # Jeremy Knickerbocker: original script

	     # Evan Schoenberg: modifications, general adium-ness

	     # Asher Haig: re-organizated as dynamic script with
	     #		   multiple options in crontabbed environments
	     #		   Added options to replace current Adium binary
	     #		   and execute new application.

#-----------------------------------------------------------------------------#

    # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
    # WARNING:							     	    #
    # If this screws your system up it's because you've changed something   #
    # that you didn't understand. Didn't your mother ever tell you not 	    #
    # to play around with other people's shell scripts? They're fragile     #
    # and they break off easily.					    #
    #								            #
    # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

    # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
    #								     	    #
    # If you really think you need to change something and you can't make   #
    # it work, it's probably a problem with your paths or your		    #
    # permissions.							    #
    #									    #
    # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

	#--------#  In a file (I use ~/.crontab):
	# Usage: #  MM HH * * * /full/path/to/script >& /path/to/log.file
	#--------#  crontab ~/.crontab

		 #  MM and HH should be two digits, 24hr time.

	   	 #  Example:  /Users/ahaig/AdiumDaily/buildDaily.sh >& \
		 #	      /Users/ahaig/AdiumDaily/log/AdiumDaily.log

		 #  That's all on ONE line or two with the \ separating them..

# If you want to use the script to build without updating via SVN, set this to
# "no".
should_update="yes"

# If you want your build to be faster but potentially contain outdated plugins and the like,
# set this to "no".
clean_build="yes"
svn="svn"

# Where all the daily build files are kept
# adium/ is created by svn checkout beneath this dir
adium_build_dir="$HOME/AdiumDaily"

# Where Adium gets built - all the source
adium_co_dir="$adium_build_dir/adium"

# Log info about the last build
lastbuild_log="$adium_build_dir/log/lastbuild.log"

# Where Adium.app comes out - it will _also_ exist in $adium_co_dir/build
build_output_dir="$adium_build_dir/build/Release"

# Normal logging records the status of each step as it completes
# Verbose mode records all svn activity
#log="normal"
log="verbose"

# Do we want to create a file with change-log information from svn? (Handled automatically if packaging or uploading)
changelog="no"

# Replace Running Adium with new version
replace_running_adium="yes"
launch_options="--user Default"

# Determines where Adium.app is installed
# set as systemwide or user or none
install_type="systemwide"				# systemwide, user, none

# Set a default install dir - overrides systemwide/user choice
# This is empty by default
install_dir=""

# For optimized setings on a G4 set $OPTIMIZATION_CFLAGS to:
# -mcpu=7450 -O3 -pipe -fsigned-char -maltivec -mabi=altivec -mpowerpc-gfxopt -mtune=7450
# Currently -Os is optimized for size
if [ -z "$OPTIMIZATION_CFLAGS" ] ; then
	OPTIMIZATION_CFLAGS="-Os"
fi

# If you want a .dmg from it (Handled automatically if uploading)
package="no"

# If for some reason you feel compelled to change the name of Adium.app....
# All I have to say is that you better not still be using NS4....

adium_app_name="Adium"

###############################################################################
#			      Stop Editing Here!! 			      #
#-----------------------------------------------------------------------------#
#	 If this were a standardized test, we would take your pencil away.    #
###############################################################################

# ensure the log directory exists
if !([ -x "$adium_build_dir/log" ]) ; then
	mkdir "$adium_build_dir/log"
fi

if !([ -z "$2" ]) ; then
	install_dir=$2
fi

if [ "$package" == "yes" ] ;  then
	changelog="yes"
	replace_running_adium="no"
fi

if [ "$install_type" == "none" ] || [ "$package" == "yes" ] && \
					[ -z "$install_dir" ] ; then
	install_dir=$build_output_dir
fi
# If $install_dir isn't set
if [ -z "$install_dir" ] ; then
	if [ "$install_type" == "systemwide" ] ; then
		if [ -x /Applications/Internet ]  ; then
			install_dir="/Applications/Internet"
							# This seems reasonable. If it's not
							# I'm still going to act like it is.
		elif [ -x /Applications ] ; then
							# I would hope it exists
			install_dir="/Applications"	# Don't you people subsort your Apps?
		fi
	elif [ "$install_type" == "user" ] ; then
		if [ -x $HOME/Applications ] ; then
			mkdir $HOME/Applications
			install_dir="$HOME/Applications"
		fi
	fi
fi

# Get the date for version tracking
today=$(date +"%Y-%m-%d")
prettydate=$(date +"%m-%d-%Y")

echo `date`

# Check to see when the last build happened
if [ -f $lastbuild_log ] ; then
	lastbuild=`grep "....-..-.." $lastbuild_log`
else
	lastbuild=$today
fi

# Everything should happen in $adium_build_dir
cd $adium_build_dir

# If adium exists we'll update it. If not we'll get it from SVN
if [ "$should_update" == "yes" ] ; then
	if !([ -x $adium_co_dir ]) ; then
		echo "$adium_co_dir does not exist. Beginning new checkout."
		echo "Begin SVN Checkout in $adium_co_dir"
		$svn co svn://svn.adiumx.com/adium/trunk $adium_co_dir
	else							# Update from SVN
		echo "Begin SVN Update in $adium_co_dir"

		# Update happens from inside adium
		cd $adium_co_dir

		if [ "$log" == "normal" ] ; then
			$svn update >& /dev/null		# Suppress output
		elif [ "$log" == "verbose" ] ; then
			$svn update
		fi

		echo "SVN Update Complete"
	fi
fi


# Time to start
cd $adium_co_dir				# Really just ./adium

if [ -e $adium_co_dir/Plugins ]; then

if [ "$clean_build" == "yes" ] ; then
	rm -rf $adium_co_dir/build
fi

# Produce Changelog
# Probably don't care about this unless we're building a .dmg for distribution
if [ "$changelog" == "yes" ] ; then
	echo "Creating ChangeLog_$prettydate relative to $lastbuild..."
	if [ -e $adium_co_dir/ChangeLog ]; then
		rm $adium_co_dir/ChangeLog
	fi

	if [ "$log" == "normal" ] ; then	# Don't Log
                $svn log > CompleteChanges
		$svn log -r{$lastbuild}:HEAD > ChangeLog_$prettydate
		ln -s $adium_co_dir/ChangeLog_$prettydate $adium_co_dir/ChangeLog >& /dev/null
	elif [ "$log" == "verbose" ] ; then
	    $svn log -v > CompleteChanges
            $svn log -vr{$lastbuild}:HEAD > ChangeLog_$prettydate
            ln -s $adium_co_dir/ChangeLog_$prettydate $adium_co_dir/ChangeLog
	fi
	if !([ -e $adium_co_dir/ChangeLog_$prettydate ]); then
		echo "No changes from $lastbuild to $prettydate" >> $adium_co_dir/ChangeLog_$prettydate
	fi
fi

# build Adium - OPTIMIZATION_CFLAGS is in the env
xcodebuild -project Adium.xcodeproj -target Adium -configuration Release

# Check for build output dir
if !([ -e $build_output_dir ]); then
    mkdir -p $build_output_dir
fi

echo Copying files...

# Package it
if [ "$package" == "yes" ] ; then			# We're building a .dmg
	if [ -x "$build_output_dir/Adium_$prettydate.dmg" ] ; then
		rm "$build_output_dir/Adium_$prettydate.dmg"
	fi
	$adium_co_dir/Utilities/Build/buildDMG.pl \
	-buildDir . -compressionLevel 9 -dmgName "Adium_$prettydate" \
	-volName "Adium_$prettydate" "$adium_co_dir/build/Release/Adium.app" \
	"$adium_co_dir/ChangeLog_$prettydate"

	cp Adium_$prettydate.dmg $build_output_dir/Adium_$prettydate.dmg
fi
if [ "$replace_running_adium" == "yes" ] && [ -x "$adium_co_dir/build/Release/Adium.app" ]; then
		osascript -e "tell application \"$adium_app_name\" to quit"
		rm -r "$install_dir/$adium_app_name.old.app"
		mv "$install_dir/$adium_app_name.app" "$install_dir/$adium_app_name.old.app"
		mv "$adium_co_dir/build/Release/Adium.app" "$install_dir/$adium_app_name.app"
		"$install_dir/$adium_app_name.app/Contents/MacOS/Adium" $launch_options &
else
		cp -r "$adium_co_dir/build/Release/Adium.app" "$install_dir/$adium_app_name.app"
fi

# Get rid of old lastbuild log
rm $lastbuild_log

# Write to new log
echo `date +"%Y-%m-%d"` >> $lastbuild_log

# And we're done
echo "Finished..."

else
	echo "Skipped everything because Plugins was not found..."
fi

echo "Exiting..."
echo
exit 0
