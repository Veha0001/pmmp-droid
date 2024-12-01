#!/usr/bin/env bash
## Modify of get.pmmp.io

CHANNEL="stable"
NAME="PocketMine-MP"
BUILD_URL=""

update=off
forcecompile=off
alldone=no
checkRoot=on
alternateurl=off

INSTALL_DIRECTORY="./"

IGNORE_CERT="no"

while getopts "rucid:v:t:" opt; do
	case $opt in
		a)
			alternateurl=on
			;;
		r)
			checkRoot=off
			;;
		u)
			update=on
			;;
		c)
			forcecompile=on
			;;
		d)
			INSTALL_DIRECTORY="$OPTARG"
			;;
    i)
			IGNORE_CERT="yes"
			;;
		v)
			CHANNEL="$OPTARG"
			;;
		t)
			BUILD_URL="$OPTARG"
			;;
		\?)
			echo "Invalid option: -$OPTARG" >&2
			exit 1
			;;
	esac
done


if [ `getconf LONG_BIT` == "32" ]; then
	echo "[ERROR] PocketMine-MP is no longer supported on 32-bit systems."
	exit 1
fi

#Needed to use aliases
shopt -s expand_aliases
type wget > /dev/null 2>&1
if [ $? -eq 0 ]; then
	if [ "$IGNORE_CERT" == "yes" ]; then
		alias download_file="wget --no-check-certificate -q -O -"
	else
		alias download_file="wget -q -O -"
	fi
else
	type curl >> /dev/null 2>&1
	if [ $? -eq 0 ]; then
		if [ "$IGNORE_CERT" == "yes" ]; then
			alias download_file="curl --insecure --silent --show-error --location --globoff"
		else
			alias download_file="curl --silent --show-error --location --globoff"
		fi
	else
		echo "error, curl or wget not found"
		exit 1
	fi
fi

if [ "$checkRoot" == "on" ]; then
	if [ "$(id -u)" == "0" ]; then
		echo "This script is running as root, this is discouraged."
		echo "It is recommended to run it as a normal user as it doesn't need further permissions."
		echo "If you want to run it as root, add the -r flag."
		exit 1
	fi
fi

if [ "$CHANNEL" == "soft" ]; then
	NAME="PocketMine-Soft"
fi

ENABLE_GPG="no"
PUBLICKEY_URL="http://cdn.pocketmine.net/pocketmine.asc"
PUBLICKEY_FINGERPRINT="20D377AFC3F7535B3261AA4DCF48E7E52280B75B"
PUBLICKEY_LONGID="${PUBLICKEY_FINGERPRINT: -16}"
GPG_KEYSERVER="pgp.mit.edu"

function check_signature {
	echo "[*] Checking signature of $1"
	"$GPG_BIN" --keyserver "$GPG_KEYSERVER" --keyserver-options auto-key-retrieve=1 --trusted-key $PUBLICKEY_LONGID --verify "$1.sig" "$1"
	if [ $? -eq 0 ]; then
		echo "[+] Signature valid and checked!"
	else
		"$GPG_BIN" --refresh-keys > /dev/null 2>&1
		echo "[!] Invalid signature! Please check for file corruption or a wrongly imported public key (signed by $PUBLICKEY_FINGERPRINT)"
		exit 1
	fi
}

function parse_json {
	echo "$1" | grep "\"$2\"" | cut -d ':' -f2- | tr -d ' ",'
}

if [[ "$BUILD_URL" != "" && "$CHANNEL" == "custom" ]]; then
	BASE_VERSION="custom"
	BUILD="unknown"
	VERSION_DATE_STRING="unknown"
	ENABLE_GPG="no"
	VERSION_DOWNLOAD="$BUILD_URL"
	MCPE_VERSION="unknown"
	PHP_VERSION="unknown"
	PM_VERSION_MAJOR="unknown"
else
	echo "[*] Retrieving latest build data for channel \"$CHANNEL\""

	VERSION_DATA=$(download_file "https://update.pmmp.io/api?channel=$(tr '[:lower:]' '[:upper:]' <<< ${CHANNEL:0:1})${CHANNEL:1}")

	if [ "$VERSION_DATA" != "" ]; then
		error=$(parse_json "$VERSION_DATA" error)
		if [ "$error" != "" ]; then
			echo "[!] Failed to get download information: $error"
			exit 1
		fi
		BASE_VERSION=$(parse_json "$VERSION_DATA" base_version)
		BUILD=$(parse_json "$VERSION_DATA" build)
		MCPE_VERSION=$(parse_json "$VERSION_DATA" mcpe_version)
		PHP_VERSION=$(parse_json "$VERSION_DATA" php_version)
		VERSION_DATE=$(parse_json "$VERSION_DATA" date)
		VERSION_DOWNLOAD=$(parse_json "$VERSION_DATA" download_url)
		PM_VERSION_MAJOR=$(echo $BASE_VERSION | cut -d "." -f1)

		if [ "$(uname -s)" == "Darwin" ]; then
			VERSION_DATE_STRING=$(date -r $VERSION_DATE)
		else
			VERSION_DATE_STRING=$(date --date="@$VERSION_DATE")
		fi

		GPG_SIGNATURE=$(parse_json "$VERSION_DATA" signature_url)

		if [ "$GPG_SIGNATURE" != "" ]; then
			ENABLE_GPG="yes"
		fi

		if [ "$BASE_VERSION" == "" ]; then
			echo "[!] Couldn't get the latest $NAME version"
			exit 1
		fi

		GPG_BIN=""

		if [ "$ENABLE_GPG" == "yes" ]; then
			type gpg > /dev/null 2>&1
			if [ $? -eq 0 ]; then
				GPG_BIN="gpg"
			else
				type gpg2 > /dev/null 2>&1
				if [ $? -eq 0 ]; then
					GPG_BIN="gpg2"
				fi
			fi
			if [ "$GPG_BIN" != "" ]; then
				gpg --fingerprint $PUBLICKEY_FINGERPRINT > /dev/null 2>&1
				if [ $? -ne 0 ]; then
					download_file $PUBLICKEY_URL | gpg --trusted-key $PUBLICKEY_LONGID --import
					gpg --fingerprint $PUBLICKEY_FINGERPRINT > /dev/null 2>&1
					if [ $? -ne 0 ]; then
						gpg --trusted-key $PUBLICKEY_LONGID --keyserver "$GPG_KEYSERVER" --recv-key $PUBLICKEY_FINGERPRINT
					fi
				fi
			else
				ENABLE_GPG="no"
			fi
		fi
	else
		echo "[!] Failed to download version information: Empty response from API"
		exit 1
	fi
fi

echo "[*] Found $NAME $BASE_VERSION (build $BUILD) for Minecraft: PE v$MCPE_VERSION (PHP $PHP_VERSION)"
echo "[*] This $CHANNEL build was released on $VERSION_DATE_STRING"

if [ "$ENABLE_GPG" == "yes" ]; then
	echo "[+] The build was signed, will check signature"
elif [ "$GPG_SIGNATURE" == "" ]; then
	if [[ "$CHANNEL" == "beta" ]] || [[ "$CHANNEL" == "stable" ]]; then
		echo "[-] This channel should have a signature, none found"
	fi
fi

echo "[*] Installing/updating $NAME on directory $INSTALL_DIRECTORY"
mkdir -m 0777 "$INSTALL_DIRECTORY" 2> /dev/null
cd "$INSTALL_DIRECTORY"
echo "[1/3] Cleaning..."
rm -f "$NAME.phar"
rm -f README.md
rm -f CONTRIBUTING.md
rm -f LICENSE
rm -f start.sh
rm -f start.bat

#Old installations
rm -f PocketMine-MP.php
rm -r -f src/

echo -n "[2/3] Downloading $NAME phar..."
set +e
download_file "$VERSION_DOWNLOAD" > "$NAME.phar"
if ! [ -s "$NAME.phar" ] || [ "$(head -n 1 $NAME.phar)" == '<!DOCTYPE html>' ]; then
	rm "$NAME.phar" 2> /dev/null
	echo " failed!"
	echo "[!] Couldn't download $NAME automatically from $VERSION_DOWNLOAD"
	exit 1
else
	download_file "https://raw.githubusercontent.com/pmmp/PocketMine-MP/${BASE_VERSION}/start.sh" > start.sh
	download_file "https://raw.githubusercontent.com/pmmp/PocketMine-MP/${BASE_VERSION}/LICENSE" > LICENSE
	download_file "https://raw.githubusercontent.com/pmmp/PocketMine-MP/${BASE_VERSION}/README.md" > README.md
	download_file "https://raw.githubusercontent.com/pmmp/PocketMine-MP/${BASE_VERSION}/CONTRIBUTING.md" > CONTRIBUTING.md
	download_file "https://raw.githubusercontent.com/pmmp/PHP-Binaries/stable/compile.sh" > compile.sh
fi

chmod +x compile.sh
chmod +x start.sh

echo " done!"

if [ "$ENABLE_GPG" == "yes" ]; then
	download_file "$GPG_SIGNATURE" > "$NAME.phar.sig"
	check_signature "$NAME.phar"
fi

if [ "$update" == "on" ]; then
	echo "[3/3] Skipping PHP recompilation due to user request"
else
	echo -n "[3/3] Obtaining PHP: detecting OS type and arch..."
	while [ "$forcecompile" == "off" ]
	do
		rm -r -f bin/ >> /dev/null 2>&1
		ARCH="$(uname -m)"
		EXTENSION=".tar.gz"

    if [[ "$ARCH" == "aarch64" ]]; then
      PLATFORM="Android"
		else
      echo -e "\n[Error] Unsupport platfrom.\n + For install on other platfrom should run: \n  curl -sL https://get.pmmp.io | bash -s - "
			exit 1
		fi

		echo -n "... downloading $PHP_VERSION for $PLATFORM $ARCH..."

    if [ "$PLATFORM" != "Android" ]; then
      download_file "https://github.com/Veha0001/pmmp-droid/releases/download/php-pm5-latest/PHP-$PLATFORM-$ARCH-PM$PM_VERSION_MAJOR.tar.gz" | tar -zx >> /dev/null 2>&-1 
      php_path=./bin/php7/bin
		fi
    
		if [ ! -d "$php_path" ]; then
			echo " no compatible prebuilt binary found!"
			break
		fi

		chmod +x "$php_path/"*

		echo -n " updating php.ini..."

		sed -i'.bak' "s/date.timezone=.*/date.timezone=$(date +%Z)/" "$php_path/php.ini"

    if [[ "$(uname -o)" == *"Linux"* ]]; then
      sed -i -E "1 s@^#\!/data/data/com.termux/files/usr/bin/(.*)@#\!/bin/\1@" "$php_path/php-config"
    fi
    
		echo -n " checking..."

		if [ "$("$php_path/php" -ddisplay_errors=stderr -r 'echo 1;' 2>/dev/null)" == "1" ]; then
			echo " done"
			alldone=yes
		else
			echo " downloaded PHP build doesn't work on this platform!"
			rm -rf bin #make sure this doesn't leave a dead binary in case compile.sh fails
		fi

		break
	done
	if [ "$alldone" == "no" ]; then
		set -e
		echo "[3/3] No prebuilt PHP found, compiling PHP automatically. This might take a while."
		echo
		logical_cpu_count=$([ "$(uname -s)" == "Darwin" ] && sysctl -n hw.logicalcpu_max || nproc --all) #Get available CPUs to pass to compile.sh and speed up compile
		if [ $logical_cpu_count -gt 0 ]; then
			echo "Starting $logical_cpu_count thread compile"
			compile_command="./compile.sh -j $logical_cpu_count -P $PM_VERSION_MAJOR"
			exec $compile_command
		else
			echo "Starting single thread compile"
			exec "./compile.sh -P $PM_VERSION_MAJOR -z $PHP_VERSION"
		fi
	fi
fi

rm compile.sh

echo "[*] Everything done! Run ./start.sh to start $NAME"
exit 0