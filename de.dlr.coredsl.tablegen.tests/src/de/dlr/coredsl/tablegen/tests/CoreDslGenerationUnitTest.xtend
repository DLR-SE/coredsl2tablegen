package de.dlr.coredsl.tablegen.tests

import com.google.inject.Inject
import com.minres.coredsl.coreDsl.DescriptionContent
import org.eclipse.xtext.generator.GeneratorContext
import org.eclipse.xtext.generator.IGenerator2
import org.eclipse.xtext.generator.InMemoryFileSystemAccess
import org.eclipse.xtext.testing.InjectWith
import org.eclipse.xtext.testing.XtextRunner
import org.eclipse.xtext.testing.util.ParseHelper
import org.eclipse.xtext.testing.validation.ValidationTestHelper
import org.eclipse.xtext.util.CancelIndicator
import org.junit.Test
import org.junit.runner.RunWith

import static org.junit.Assert.*

@RunWith(XtextRunner)
@InjectWith(CoreDslInjectorProvider)
class CoreDslGenerationUnitTest{

    @Inject IGenerator2 generator
    
    @Inject extension ParseHelper<DescriptionContent> parseHelper

    @Inject ValidationTestHelper validator

    def CharSequence addInstructionContext(CharSequence str)'''
        InstructionSet TestISA {
            architectural_state {
                unsigned XLEN; 
                const unsigned FLEN=32;
                register unsigned<32> PC [[is_pc]];
                register unsigned<32> X[32];
            }
            instructions {
                «str»
            }
        }
        Core TestCore provides TestISA {
            architectural_state {
                 XLEN=32; 
            }
        }
    '''
    
    @Test
    def void genDisabledInstr() {
        val content =  '''
            CLI {
                encoding: 0b010 :: imm[5:5] :: rd[4:0] :: imm[4:0] :: 0b01;
                behavior: {
                    if(rd == 0)   //rd==0 is a hint, so no trap
                       X[rd] = (unsigned<32>)(signed)imm;
                }
            }
        '''.addInstructionContext.parse
        validator.assertNoErrors(content)
        val fsa = new InMemoryFileSystemAccess()
        generator.doGenerate(content.eResource, fsa, new GeneratorContext => [
            cancelIndicator = CancelIndicator.NullImpl
        ])
        val res = fsa.textFiles
    }
    
    @Test
    def void genEnabledInstr() {
        val content =  '''
            CLI [[hls]]{
                encoding: 0b010 :: imm[5:5] :: rd[4:0] :: imm[4:0] :: 0b01;
                behavior: {
                    if(rd == 0)   //rd==0 is a hint, so no trap
                       X[rd] = (unsigned<32>)(signed)imm;
                }
            }
        '''.addInstructionContext.parse
        validator.assertNoErrors(content)
        val fsa = new InMemoryFileSystemAccess()
        generator.doGenerate(content.eResource, fsa, new GeneratorContext => [
            cancelIndicator = CancelIndicator.NullImpl
        ])
        val res = fsa.textFiles
    }    
 }
