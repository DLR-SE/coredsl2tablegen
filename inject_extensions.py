#!/bin/python3
# inject_extension.py
#
# Given LLVM(15-ish) source ornamented with site markers and the fragments
# of code generated from the CoreDSL2TableGen tool, inserts those fragments

import os
import argparse
import yaml
import subprocess
from email.utils import formatdate


class injectionSite:
    siteTag = ''
    fullPath = ''
    startMark = ''
    endMark = ''
    # line + len magic values to give 0,0 for new files
    siteLine = -1
    siteLen = 0
    payload = ''

    def __init__(self, siteTag, fullPath, payload):
        self.siteTag = siteTag
        self.fullPath = fullPath
        self.payload = payload

    def hasPatchSite(self):
        return self.siteTag

    def findSite(self):
        self.startMark = self.siteTag + ' - INSERTION_START'
        self.endMark = self.siteTag + ' - INSERTION_END'
        with open(self.fullPath) as src:
            lines = src.readlines()
            for line in lines:
                if line.find(self.startMark) != -1:
                    self.startMark = line
                    self.siteLine = lines.index(line)
                elif line.find(self.endMark) != -1:
                    self.endMark = line.rstrip('\n')
                    self.siteLen = lines.index(line) - self.siteLine + 1
                    break
                elif self.siteLine >= 0:
                    # Accumulate all lines between the start mark and the end
                    # as part of the mark, so the new lines get injected just
                    # before the end mark
                    self.startMark += line
        return self.siteLen > 0


class patchSet:
    patches = {}

    def add(self, filename, filepath, payload):
        self.patches[filename] = injectionSite(filename, filepath, payload)

    def findSites(self):
        for patch in self.patches.values():
            if patch.hasPatchSite() and not patch.findSite():
                raise ValueError('Start mark for injecting in {0} not found'.format(patch.fullPath))

    def generatePatches(self):
        ps = ''
        # Build minimal patch header for 'git am'
        userName = "bob" #subprocess.check_output(['git', 'config', 'user.name']).decode('utf-8').strip()
        userEmail = "bob@bob.com" #subprocess.check_output(['git', 'config', 'user.email']).decode('utf-8').strip()
        ps += 'From: {0} <{1}>\n'.format(userName, userEmail)
        ps += 'Date: {0}\n'.format(formatdate())
        ps += 'Subject: [PATCH] Instructions injected\n\n\n'

        for patch in self.patches.values():
            insPayload = '+' + patch.payload.replace('\n', '\n+')
            if patch.hasPatchSite():
                # Updating existing file
                origFile = 'a/' + patch.fullPath
                newFile = 'b/' + patch.fullPath
                newStart = patch.siteLine + 1
                newLen = patch.payload.count('\n') + 1 + patch.siteLen
                # ensure all existing lines in the match prefixed by a space
                patch.startMark = patch.startMark.rstrip('\n').replace('\n', '\n ')
                insPayload = ' {0}\n{1}\n {2}'.format(patch.startMark, insPayload, patch.endMark)
            else:
                # Adding new file
                origFile = '/dev/null'
                newFile = 'b/' + patch.fullPath
                newStart = 1
                newLen = patch.payload.count('\n') + 1
            ps += '''--- {0}
+++ {1}
@@ -{2},{3} +{4},{5} @@
{6}
'''.format(     origFile,
                newFile,
                patch.siteLine + 1,
                patch.siteLen,
                newStart,
                newLen,
                insPayload )
        return ps

# The sole argument is a YAML file describing a list of extensions to process, of the format:
#
# - extension
#   name: (short name for extension, used as identifier and for enabling target feature)
#   description: (short human-readable description for display)
#   instructions: (path to .td file specifying instructions)
#   BuiltinsRISCV.def: (path to table fragment for Builtins entries)
#   CGBuiltin.cpp: (path to code fragment for CGBuiltin switch)
#   IntrinsicsRISCV.td: (path to table fragment for IntrinsicsRISCV entries)
#
# The extension name needn't be unique, e.g. two sets of extension instructions can share the
# same name. Then the clang switch "-target-feature +x(extension name)" will enable both sets.
# The name will prefixed with "x" and made lower-case as a control switch, e.g. "S4EMAC" becomes
# "xs4emac" as an option name.
parser = argparse.ArgumentParser(description="Generate patch file for adding extension to LLVM")
parser.add_argument("index_file", help="list of code fragments to inject")
args = parser.parse_args()
with open(args.index_file) as file:
    index = yaml.safe_load(file)

patches = patchSet();
patchFiles = [
    ['BuiltinsRISCV.def', 'clang/include/clang/Basic/BuiltinsRISCV.def'],
    ['CGBuiltin.cpp', 'clang/lib/CodeGen/CGBuiltin.cpp'],
    ['IntrinsicsRISCV.td', 'llvm/include/llvm/IR/IntrinsicsRISCV.td']
]
extnNames = {}
RISCVInstrInfo = ''
for extn in index:
    # Accumulate the list of extension namese
    extnNames[extn['name']] = extn['description']
    # Include the instuction files
    instrFilename = os.path.basename(extn['instructions'])
    RISCVInstrInfo += r'include "{0}"'.format(instrFilename)
    filePath = os.path.join(os.path.dirname(args.index_file), extn['instructions'])
    with open(filePath) as file:
        payload = file.read().rstrip()
    patches.add('', os.path.join('llvm/lib/Target/RISCV', instrFilename), payload)

    # include the file fragments for the per-instruction patches
    for fileTag in patchFiles:
        if fileTag[0] in extn:
          fileName = extn[fileTag[0]]
          fileName = os.path.join(os.path.dirname(args.index_file), fileName)
          with open(fileName) as file:
              payload = file.read()
          patches.add(fileTag[0], fileTag[1], payload)

# Build the extension-name-dependent patches
RISCVISAInfo = ''
RISCV = ''
RISCVSubTargetPrivate = ''
RISCVSubTargetPublic = ''
for extn in extnNames.items():
    extnOpt = "x" + extn[0].lower()
    RISCVISAInfo += r'    {{"{0}", RISCVExtensionVersion{{0, 1}}}},'.format(extnOpt)
    RISCV += r"""
def FeatureCustExt{1}
    : SubtargetFeature<"{0}", "HasCustExt{1}", "true",
                       "'{0}'">;
def HasCustExt{1} : Predicate<"Subtarget->hasCustExt{1}()">,
                             AssemblerPredicate<(all_of FeatureCustExt{1}),
                             "'{0}' ({2})">;
""".format(extnOpt, extn[0], extn[1])
    RISCVSubTargetPrivate += r'  bool HasCustExt{0} = false;'.format(extn[0])
    RISCVSubTargetPublic += r'  bool hasCustExt{0}() const {{ return HasCustExt{0}; }}'.format(extn[0])

# Apply the extension-name-dependent patches
patches.add('RISCVISAInfo.cpp', 'llvm/lib/Support/RISCVISAInfo.cpp', RISCVISAInfo)
patches.add('RISCVFeatures.td', 'llvm/lib/Target/RISCV/RISCVFeatures.td', RISCV)
patches.add('RISCVInstrInfo.td', 'llvm/lib/Target/RISCV/RISCVInstrInfo.td', RISCVInstrInfo)

# Find injection locations
patches.findSites()

# Generate patch file
print(patches.generatePatches())
