package de.dlr.coredsl.tablegen

import com.google.inject.Binder
import com.minres.coredsl.CoreDslRuntimeModule
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.generator.IGenerator2
import org.eclipse.xtext.generator.JavaIoFileSystemAccess
import org.eclipse.xtext.generator.IOutputConfigurationProvider
import javax.inject.Singleton
import de.dlr.coredsl.tablegen.GeneratorOutputConfigurationProvider

/** 
 * Use this class to register components to be used at runtime / without the Equinox extension registry.
 */
@SuppressWarnings("all") class CoreDslGeneratorModule extends CoreDslRuntimeModule {
    override void configure(Binder binder) {
        super.configure(binder);
        //binder.bind(TemplateEngine).to(SimpleTemplateEngine);
        binder.bind(IOutputConfigurationProvider)
            .to(GeneratorOutputConfigurationProvider)
            .in(Singleton);
        binder.bind(IFileSystemAccess2)
            .to(JavaIoFileSystemAccess)
    }

    def Class<? extends IGenerator2> bindIGenerator2() {
        // return DummyGenerator.class;
        return typeof(CoreDslTableGenGenerator)
    }

}
