## Python Minimal DE (Development Environment) for Linux
This project is mainly designed to add offline operation capabilities to Python development environments.

Intended to be deployed on **Debian** systems. 
<br>

### Addressing Problems and Goals
Traditional Python systems are cloud dependent and are unsuitable for complete offline operation.

To be honest, this system does also require internet connectivity for initial dependency resolution and source code collection. Rather, it aids in air-gapping or creating a snapshot for later use if cloud services become unavailable.

Yes, I know that [UV](https://docs.astral.sh/uv/) is way faster and also has capabilities for offline operation/deployment, but I really like building my own tools (even if they are quite crappy) and making things is often a great way of learning. Even if they are not that useful.

The primary goal of this system is not to replace any existing tools. Instead, it builds upon them and makes something that solves a problem that I've been facing for a long time.

<div align="center">

***Reduction of Cloud Dependent Services***

</div>

> [!WARNING]  
> * This project is **NOT RECOMMENDED** for production use (unless you **REALLY** know what you are doing)
> * Migrating compiled binaries across machines **WILL** cause issues. Re-compile the binaries from source on the new device (applicable for both online and air-gapped deployments)

___

### Operation
Once the repository is extracted (either via [cloning](https://docs.github.com/en/repositories/creating-and-managing-repositories/cloning-a-repository) or by manually downloading the source code) you must navigate to the ```~/Python-Minimal-DE-main/runtime/``` (assuming that you have placed the contents inside the home directory of the ```$USER```), run the following command to activate the runtime scripts.
```bash
chmod +x *.sh
```
Run the following command to resolve dependencies that are required to build Python from source and for the general operation of this system.
```bash
./dep_engine.sh --resolve-online
```
Test it out by running ```which make``` and if it returns ```/usr/bin/make``` then rest assured that everything went accordingly. 

Now go back to  ```~/Python-Minimal-DE-main/``` as this will be the root of your system's shell while operating this project.

<br>

**STEP 1:** Initialize the system and populate the system with the available Python versions and download URLs.
```bash
make system_init
```
<br>

**STEP 2:** Edit the **Makefile**, change the ```python_version``` to the desired Python version (it is set to *v3.12*) and download its source code.

> [!NOTE]
> If ```python_patch_level``` is left blank, the system will automatically assume that the user requested the latest patch for that major-minor release combination. To get the **EXACT** version (e.g. 3.12.10) set the ```python_patch_level``` variable accordingly (which in this case is already set to 10).

```bash
make download_src
```
> [!NOTE]
> If you want to download multiple versions of Python, edit the ```python_vers_multi``` variable inside the **Makefile** (an example is already set up).

> [!IMPORTANT]
> The multi-source download feature has not been tested for exact versions (specified to the patch level). It will download the latest patch of the versions specified in the ```python_vers_multi``` variable.

To trigger the multiple source download sequence, run the following.
```bash
make download_src_array
```

**RECOMMENDED:** Verify the downloaded source packages (has been tested for both single and multi-version local caches).
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
> The compilation will take a **CONSIDERABLE AMOUNT** of time (depending on your system). So, being patient is generally recommended (as for many things in life).


<br>

**STEP 4:** Create virtual environments
```bash
make create_venv
```
For multiple versions.
```bash
make create_venv_array
```

> [!TIP]
> * Test the Python environment with ```make print_venv_details``` and ```make print_venv_details_array``` for deployments that have multiple versions.
> * This check is also recommended to be performed after completing **STEP 5**

<br>

**STEP 5:** Populate the virtual environment with packages

> [!NOTE]
> The packages in the ```pkglist.txt``` file will be downloaded according to the version of Python based on the value of the ```python_version``` variable (and the patch level if ```python_patch_level``` is specified).

> [!IMPORTANT]
> The ```pkglist.txt``` file has version specification methods
> * Exact version is set by ```==```
> * The latest available version is set when just the package name is written without any trailing characters or alphanumeric symbols

> [!NOTE]
> The package collection and "installation" is done one version at a time (based on ```python_version``` and its accompanying ```python_patch_level```).

```bash
make cache_packages
```
Followed by,
```bash
make load_packages
```
<br>

Finally run the ```main.py``` file with ```make```
___

### Deployment on Air-Gapped Systems

> [!IMPORTANT]
> * This should be performed on an online machine with a near **IDENTICAL** software build (GPU acceleration and special hardware specific requirements are not taken into consideration). For more information click [here](https://github.com/SadBIOS/Cheat-Sheet/blob/main/AirGapped_Debian_Updates.md).
> * Migrating pip packages over requires fully built versions of Python that match the deployment versions.
> > * **MUST** be done after creating the base dependencies generated by ```./dep_engine.sh --build-offline``` (keep the ```py_build_dependencies.tar.gz``` archive located in ```~/Python-Minimal-DE-main/runtime/``` in a separate location before building from source)
> > * Once built, compress the contents of ```~/Python-Minimal-DE-main/runtime/data/pip_packages/```
> > * Contents of the pip archive must be placed in ```~/Python-Minimal-DE-main/runtime/data/pip_packages/``` for correct operation
> > * This step can be repeated indefinitely
<br>

**STEP 1:** Create a copy of the system (i.e. Git repo) on the target machine and assuming that it's placed within the ```$HOME``` directory of the user

<br>

**STEP 2:** Run the following command to create an offline copy of required dependencies and source files

> [!NOTE]
> The command for multiple versions are shown here as it is recommended (at the latest patch level) unless required otherwise.

Navigate to ```~/Python-Minimal-DE-main/runtime/``` and run the following commands.
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

Compress the ```~/Python-Minimal-DE-main/``` directory and copy the archive over to the air-gapped machine (practice OPSEC procedures as a general recommendation).

<br>

**STEP 3:** On the air-gapped machine after extracting the archive to the ```$HOME``` directory of the user (this is an assumption for ease of use), navigate to ```~/Python-Minimal-DE-main/runtime/``` and run the following
```bash
./dep_engine.sh --resolve-offline
```
This can also be done by placing the ```py_build_dependencies.tar.gz``` file in ```~/Python-Minimal-DE-main/runtime/``` instead of the whole directory.

Finally, perform the compilation steps in [this](#operation) section. Omit the ```make cache_packages``` command as the pip packages are loaded from a local repository.

> [!NOTE]
> Keeping the ```py_build_dependencies.tar.gz``` and all required packages (a compressed archive of ```~/Python-Minimal-DE-main/runtime/data/pip_packages/```) is the most efficient method for operation, given the end deployment environment is properly planned out.
___

> [!IMPORTANT]  
> Tested and built on the following builds
> * Debian 13.5 *"Trixie"*, Kernel **6.12.94+deb13-amd64**
> * Debian 13.5 *"Trixie"*, Kernel **6.12.95+deb13-amd64**
> * Debian 13.6 *"Trixie"*, Kernel **6.12.96+deb13-amd64**
> * LMDE 7 *"Gigi"*, Kernel **6.12.96+deb13-amd64** (based on Debian 13.0)
>
> ---
> Future editions will streamline multi-version installation and package management procedures, which will be added **Soon<sup>TM</sup>**
