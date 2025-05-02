# container-tools-builder

This containerfile is a builder for the latest set of podman etc. container tools for Debian Bookworm. It will provide a tarball of binaries for the following projects:  
[Podman - A tool for managing OCI containers and pods.](https://podman.io/)  
[Buildah - A tool that facilitates building OCI container images](https://buildah.io/)  
[go-md2man - used by Buildah](https://github.com/cpuguy83/go-md2man)  
[Passt / Pasta - default networking for Podman >= 5.0](https://passt.top/)  
[Rootlesskit](https://github.com/rootless-containers/rootlesskit)  
[Crun - container runtime](https://www.redhat.com/en/blog/introduction-crun)  

The original need was for improved NVidia Container Device Interface (CDI) support, particularly for `podman build`, in Bookworm. 

## Usage
```
podman build -t container-tools-builder .
podman create --name builder_container container-tools-builder
podman cp builder_container:/home/build/bin.tar .
podman rm builder_container
```

Untar the binary in a directory and put that at the front of your PATH when you need cutting-edge container tools. You will need to explicitly specify the crun runtime for podman (or just set it as the new default).

e.g.
`podman build --tag llamacpp -f Containerfile --device nvidia.com/gpu=all --security-opt=label=disable --runtime ~/.local/bin/crun .`