## Python Minimal DE (Development Environment) for Linux
This project is mainly designed to make a completely offline capable development of Python. Developed for deployment in **Debian** systems. 
<br>

### Addressing Problems and Goals
Traditional Python systems require internet dependencies are unsuitable for complete offline operation.

Yes, I know that [UV](https://docs.astral.sh/uv/) is way faster and also has capabilities for offline operation/deployment but I really like building my own tools (even if they are quite crappy) and making things is often a great way of learning. Even if they are not that useful.

The primary goal of this system is not to replace any existing tools. Rather, build upon them and make something that solves a problem that I've been facing for a long time. ***Reduction of Cloud Dependent Services***

> [!WARNING]  
> This project is **NOT RECOMMENDED** for production use.

___

### Operation
Once a the repository is extracted (either via [cloning](https://docs.github.com/en/repositories/creating-and-managing-repositories/cloning-a-repository) or by manually downloading the source code) you must navigate to the ```~/Python-Minimal-DE-main/runtime/ ``` (assuming that you have place the contents inside the home directory of the```$USER```), run the following command to activate the runtime scripts.
```bash
chmod +x *.sh
```
Run the following command to resolve dependencies that are required to build python from source and for the general operation of this system.
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

> [!WARNING]
> The multi-source download feature has not been tested for exact versions (specified to the patch level). It will download the latest patch of the versions specified in the ```python_vers_multi``` variable.

To trigger the multiple source download sequence, run the following.
```bash
make download_src_array
```

**RECOMMENDED:** Verify the downloaded source packages
```bash
make verify_local_sources
```
For multiple sources

```bash
```
___

### Deployment on Air-Gapped Systems
___

> [!IMPORTANT]  
> Tested and built on the following builds
> * Debian 13.5 *"Trixie"* Kernel **6.12.94+deb13-amd64**
> * Debian 13.5 *"Trixie"* Kernel **6.12.95+deb13-amd64**
> * Debian 13.6 *"Trixie"* Kernel **6.12.96+deb13-amd64**
