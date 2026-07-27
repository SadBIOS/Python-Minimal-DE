## Python Minimal DE (Development Environment) for Linux
This project is mainly designed to make a completely offline capable development of Python. Developed for deployment in **Debian** systems. 
<br>

### Addressing Problems and Goals
Traditional Python systems require internet dependencies are unsuitable for complete offline operation.

Yes, I know that [UV](https://docs.astral.sh/uv/) is way faster and also has capabilities for offline operation/deployment but I really like building my own tools (even if they are quite crappy) and making things is often a great way of learning. Even if they are not that useful.

The primary goal of this system is not to replace any existing tools. Rather, build upon them and make something that solves a problem that I've been facing for a long time.

<div align="center">

***Reduction of Cloud Dependent Services***

</div>

> [!WARNING]  
> * This project is **NOT RECOMMENDED** for production use (unless you **REALLY** know what you are doing)
> * Migrating compiled binaries across machines **WILL** cause issues. Re-compile the binaries from source on the new device (applicable for both online and air-gapped deployments)

___

### Operation
Once a the repository is extracted (either via [cloning](https://docs.github.com/en/repositories/creating-and-managing-repositories/cloning-a-repository) or by manually downloading the source code) you must navigate to the ```~/Python-Minimal-DE-main/runtime/ ``` (assuming that you have place the contents inside the home directory of the```$USER```), run the following command to activate the runtime scripts.
```bash
chmod +x *.sh
```
Run the following command to resolve dependencies that are required to build Python from source and for the general operation of this system.
```bash
./dep_engine.sh --resolve-online
```
Test it out by running ```which make``` and if it returns ```/usr/bin/make``` then rest assured that everything went accordingly. 

Now go back to  ```~/Python-Minimal-DE-main/``` as this will be the root of your systems shell while operating this project.

<br>

**STEP 1:** Initialize the system and populate the system with available Python versions and download URLs.
```bash
make system_init
```
<br>

**STEP 2:** Edit the **Makefile**, change the ```python_version``` to the desired Python version (it is set to *v3.12*) and download it's source code.

> [!NOTE]
> If ```python_patch_level``` is left blank the system will automatically assume that the user requested the latest patch for that major-minor release combination. To get the **EXACT** version (e.g. 3.12.10) set the ```python_patch_level``` variable accordingly (which in this case is already set to 10).

```bash
make download_src
```
> [!NOTE]
> If you want to download multiple versions of Python edit the ```python_vers_multi``` variable inside the **Makefile** (an example is already set up).

> [!IMPORTANT]
> The multi-source download feature has not been tested for exact versions (specified to the patch level). It will download the latest patch of the versions specified in the ```python_vers_multi``` variable.

To trigger the multiple source download sequence, run the following.
```bash
make download_src_array
```

**RECOMMENDED:** Verify the downloaded source packages (has been tested for both single/multi-version local caches).
```bash
make verify_local_sources
```

<br>

**STEP 3:** Building from source.
```bash
make build_src
```
For multiple sources.
```bash
make build_src_array
```

> [!TIP]
> The compilation will take a **LOT** of time (depending on your system). So, being patient is generally recommended (as for many things in life).


<br>

**STEP 4:** Create Virtual Environment
```bash
make create_venv
```
For multiple versions
```bash
make create_venv_array
```

> [!TIP]
> * Test the Python environment with ```make print_venv_details``` and ```make print_venv_details_array``` for deployments that have multiple versions.
> * This check is also recommended to be performed after completing **STEP 5**

<br>

**STEP 5:** Populate the Virtual Environment with packages

> [!NOTE]
> The packages in the ```pkglist.txt``` file will be downloaded according to the version of Python based on the value of the ```python_version``` variable (and the patch level if ```python_patch_level``` is specified).

> [!IMPORTANT]
> The ```pkglist.txt``` file has version specification metthods
> * Exact version is set by ```==```
> * The latest available version is set when just the package name is written without any trailing characters or alphanumeric symbols

> [!NOTE]
> The package collection and "installation" is done one version at a time (based on ```python_version``` and it's accompanying ```python_patch_level```).

```bash
make cache_packages
```
Followed by
```bash
make load_packages
```
<br>

Finally run the ```main.py``` file with ```make```
___

### Deployment on Air-Gapped Systems

> [!IMPORTANT]
> This should be performed on a online machine with a near **IDENTICAL** software build (GPU acceleration and special hardware specific requirements are not taken into consideration). For more information click [here](https://github.com/SadBIOS/Cheat-Sheet/blob/main/AirGapped_Debian_Updates.md).

<br>

**STEP 1:** Create a copy of the system (i.e. git repo) on the target machine and assuming that it's placed within the ```$HOME``` directory of the user

<br>

**STEP 2:** Run the following command to create an offline copy of required dependencies and source files

> [!NOTE]
> The command for multiple versions are shown here as it is recommended (at the latest patch level) unless required otherwise.

Navigate to ```~/Python-Minimal-DE-main/runtime/ ``` and run the following commands
```bash
./dep_engine.sh --build-offline
```
```bash
./src_engine.sh --force-build-cache
```
Repeat the following for every required version. 
```bash
./src_engine.sh --download-max-patch-lvl X.Y
```
Although the highest patch level is recommended, you can run ```src_engine.sh --download-exact X.Y.Z``` to download a specific version.

Compress the ```~/Python-Minimal-DE-main/``` directory and copy it over to the air-gapped machine (practice OPSEC procedures as a general recommendation).

<br>

**STEP 3:** On the air-gapped machine after extracting the archive to the ```$HOME``` directory of the user (this is an assumption for ease of use), navigate to 
```bash
./
```
___

> [!IMPORTANT]  
> Tested and built on the following builds
> * Debian 13.5 *"Trixie"* Kernel **6.12.94+deb13-amd64**
> * Debian 13.5 *"Trixie"* Kernel **6.12.95+deb13-amd64**
> * Debian 13.6 *"Trixie"* Kernel **6.12.96+deb13-amd64**
>
> ---
> Future editions will streamline multi-version installation and package management procedures, which will come **Soon<sup>TM</sup>**
