# Build an x86_64 GCC toolchain for Linux on OSX
## Synopsis

This builds an x86_64 GCC toolchain for Linux on OSX.

This is based on the extremely helpful script that appears at the end of the article describing how to cross-compile a toolchain, located here:
http://preshing.com/20141119/how-to-build-a-gcc-cross-compiler/

The script itself is in a Gist, located here: https://gist.github.com/preshing/41d5c7248dea16238b60

## Installation notes

- You will need `gettext` and `gnu-sed` installed, plus possibly other packages (I have a load installed on my machine already, so I don't know what exactly you'll need on yours).  I suggest installing using brew.
- The makefiles require gnu-sed, not the normal sed that comes with OSX.  If you don't want to mess with the normal sed, perhaps add to the front of PATH the path to gnu-sed before you run this script?  
  Installing using brew will result in the installation of a binary called `gsed` which is not what you want and you'd have to symlink to it from `sed` to get this to work.  You can get
  around the problem by installing like this: `brew install gnu-sed --with-default-names`, which will keep the name as `sed`.
- Edit `vars.sh` first to set package versions.  The versions that will result in a successful build will vary - some package versions will work, some will not.
- You will need to increase the number of open files that are permitted by OSX (check your existing limit using `ulimit -a`). I use 4096.
- This needs to be run/built in a case sensitive partition.  You can create one using OSX's disk utility - I used a 10GB sparse image.  It will be installed to a destination of your choosing, so you can delete the partition file when you're done.
- Clone this repository, change into the directory, download the packages then build.

~~~~
# assumes gnu-sed v4.2.2 has been installed using brew and the default name has been kept 
export PATH=/usr/local/Cellar/gnu-sed/4.2.2/bin:$PATH
ulimit -n 4096
git clone https://github.com/johnlondon/Cross-compile-toolchain-for-linux-on-OSX.git
./download.sh
./build.sh
~~~~


## License

I was helped by Waldemar Brodkorb on the crosstool-ng mailing list (https://sourceware.org/ml/crossgcc/) as I couldn't get glibc to compile properly with ct-ng.  He said that for x86_64 toolchain creation you are required to provide some implementation of endian.h.
The files in the `endian` directory are taken from his OpenADK repository (http://cgit.openadk.org/cgi/cgit/openadk.git/).  They are covered by a BSD license, according to the OpenADK license file.

Use this as you see fit, I hope it helps someone.
