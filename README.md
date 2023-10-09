# CoreDSL2Tablegen

CoreDSL to TableGen converter / code generator

## Dependencies

- `Java` and
- `Maven`

must reside inside `$PATH`

## Usage

`generate_extension.sh` invokes the Java code that does the conversion. It requires both the CoreDSL specification of an extension and the supplementary metadata in a YAML file. The CoreDSL file will typically include other CoreDSL definition files from the `RISCV-CoreDSL-Extensions` repository therefore it will be easiest to place the CoreDSL file in this directory. The repository has a sample extension `s4e-mac.core_desc` which together with the accompanying metadata `s4e-mac-extension.yaml` is used in the following walkthrough.

Sample use:

    ./generate_extension.sh ../RISCV-CoreDSL-Extensions/s4e-mac.core_desc ../RISCV-CoreDSL-Extensions/s4e-mac-extension.yaml

This generates the index file `extensions.yaml` and a directory containing code fragments `s4emac`. If it fails (typically by throwing an exception) then try running with the "-v" switch for clues, check that instructions are described in the metadata, spelled identically, etc.

To add the extension to LLVM a patch file must be created and merged into the source. This requires the accompanying `llvm` repository which has been ornamented with comments specifying the insertion points for the code fragments, then:
1. From the base of the LLVM source tree generate the patch file by passing the index `extensions.yaml` through `inject_extensions.py`:
```
cd ../llvm 
../CoreDSL2TableGen/inject_extensions.py ../CoreDSL2TableGen/extensions.yaml > s4e-mac.patch
```
2. Merge the patch:
```
git am s4e-mac.patch
```
3. Re-build LLVM (the overall extensible-compiler README has further guidance)

## Reverting the extension

To patch LLVM again, for example after modifying the input CoreDSL, it is necessary to remove the existing patch. This can be conveniently done by dropping the commit that merged it, e.g.

    git reset --hard HEAD~1

## Rebuilding CoreDSL2Tablegen

Written in Xtend (Java-derived language for Xtext, used by Eclipse to describe languages), compiles to JAR files for execution. The JAR files are rebuilt by a Maven script:

    mvn package
