package de.dlr.coredsl.tablegen

import java.util.Set
import org.eclipse.xtext.generator.IFileSystemAccess
import org.eclipse.xtext.generator.IOutputConfigurationProvider
import org.eclipse.xtext.generator.OutputConfiguration

class GeneratorOutputConfigurationProvider implements IOutputConfigurationProvider {
    public static final String GEN_ONCE_OUTPUT = "gen-once"

    /** 
     * @return a set of {@link OutputConfiguration} available for the generator
     */
    override Set<OutputConfiguration> getOutputConfigurations() {
        var OutputConfiguration defaultOutput = new OutputConfiguration(IFileSystemAccess::DEFAULT_OUTPUT)
        defaultOutput.setDescription("Output Folder")
        defaultOutput.setOutputDirectory("./src-gen")
        defaultOutput.setOverrideExistingResources(true)
        defaultOutput.setCreateOutputDirectory(true)
        defaultOutput.setCleanUpDerivedResources(true)
        defaultOutput.setSetDerivedProperty(true)
        var OutputConfiguration readonlyOutput = new OutputConfiguration(GEN_ONCE_OUTPUT)
        readonlyOutput.setDescription("Read-only Output Folder")
        readonlyOutput.setOutputDirectory("./src")
        readonlyOutput.setOverrideExistingResources(false)
        readonlyOutput.setCreateOutputDirectory(true)
        readonlyOutput.setCleanUpDerivedResources(false)
        readonlyOutput.setSetDerivedProperty(false)
        return newHashSet(defaultOutput, readonlyOutput)
    }
}
