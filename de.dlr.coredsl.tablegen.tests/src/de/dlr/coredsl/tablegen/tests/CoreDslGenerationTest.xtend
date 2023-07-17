package de.dlr.coredsl.tablegen.tests

import com.google.inject.Inject
import com.minres.coredsl.coreDsl.DescriptionContent
import org.eclipse.emf.ecore.util.EcoreUtil
import org.eclipse.xtext.generator.GeneratorContext
import org.eclipse.xtext.generator.IGenerator2
import org.eclipse.xtext.generator.InMemoryFileSystemAccess
import org.eclipse.xtext.testing.InjectWith
import org.eclipse.xtext.testing.XtextRunner
import org.eclipse.xtext.testing.util.ParseHelper
import org.eclipse.xtext.util.CancelIndicator
import org.junit.Test
import org.junit.runner.RunWith

import static org.junit.Assert.*
import static extension com.google.common.io.CharStreams.*
import com.minres.coredsl.coreDsl.InstructionSet
import java.io.FileReader
import org.eclipse.xtext.testing.validation.ValidationTestHelper

@RunWith(XtextRunner)
@InjectWith(CoreDslInjectorProvider)
class CoreDslGenerationTest{

    @Inject IGenerator2 generator
    
    @Inject extension ParseHelper<DescriptionContent> parseHelper

    @Inject ValidationTestHelper validator

    val isa_rv32i = '''
Core RV32I {
    architectural_state {
        unsigned int XLEN, FLEN;
        unsigned CSR_SIZE = 4096;
        unsigned REG_FILE_SIZE=32;
        register unsigned<XLEN> PC [[is_pc]];
        register unsigned<XLEN> X[REG_FILE_SIZE];
        extern char MEM[1<<XLEN];
        extern unsigned CSR[CSR_SIZE];
    }
    instructions [[hls]] { 
       ADDI {
            encoding: imm[11:0] :: rs1[4:0] :: 0b000 :: rd[4:0] :: 0b0010011;
            behavior: {
                X[rd] = X[rs1] + imm;            
            }
        }
        SLTI {
            encoding: imm[11:0] :: rs1[4:0] :: 0b010 :: rd[4:0] :: 0b0010011;
            behavior: {
                X[rd] = X[rs1] < imm? 1 : 0;                
            }
        }
        SLTIU {
            encoding: imm[11:0] :: rs1[4:0] :: 0b011 :: rd[4:0] :: 0b0010011;
            behavior: {
                X[rd] = X[rs1] < imm? 1 : 0;
            }
        }
        SW {
            encoding: imm[11:5] :: rs2[4:0] :: rs1[4:0] :: 0b010 :: imm[4:0] :: 0b0100011;
            assembly:"{name(rs2)}, {imm}({name(rs1)})";
            behavior: {
                int offset =  X[rs1] + imm;
                MEM[offset] = X[rs2];
            }
        }
        JAL[[no_cont]] {
            encoding:imm[20:20] :: imm[10:1] :: imm[11:11] :: imm[19:12] :: rd[4:0] :: 0b1101111;
            behavior: {
                if(rd!=0) X[rd] = (unsigned)PC;
                PC = PC+imm;
            }
        }
    }
}
        '''
 
    @Test
    def void loadSimpleModel() {
        val content = new FileReader('inputs/isa_1.core_desc').readLines.join('\n').parse
        validator.assertNoErrors(content)
                
        val InstructionSet result = content.definitions.get(0) as InstructionSet
        assertNotNull(result)
        assertEquals("RV32I", result.name)
        assertNull(result.superType)
        assertEquals(9, result.declarations.size())
        assertNotNull(result.instructions)

        assertEquals(5, result.instructions.size)
        val i0 = result.instructions.get(0);
        assertEquals("ADDI", i0.name)
        assertEquals(5, i0.encoding.fields.size)

        val i1 = result.instructions.get(1);
        assertEquals("SLTI", i1.name)
        assertEquals(5, i1.encoding.fields.size)

        val i2 = result.instructions.get(2);
        assertEquals("SLTIU", i2.name)
        assertEquals(5, i2.encoding.fields.size)

        val i3 = result.instructions.get(3);
        assertEquals("SW", i3.name)
        assertEquals(6, i3.encoding.fields.size)

    }
        
    @Test
    def void generateCpp() {
    	val content = parseHelper.parse(isa_rv32i)
        assertNotNull(content)
    	assertEquals(1, content.definitions.size)
        val resource = content.eResource
        EcoreUtil.resolveAll(resource);
        validator.assertNoErrors(content)
        assertEquals(0, resource.errors.size)
        assertEquals(0, resource.warnings.size)
        val fsa = new InMemoryFileSystemAccess()
        generator.doGenerate(content.eResource, fsa, new GeneratorContext => [
			cancelIndicator = CancelIndicator.NullImpl
		])
		println(fsa.textFiles)        
        assertEquals(1,fsa.textFiles.size)
        assertTrue(fsa.textFiles.containsKey("DEFAULT_OUTPUTRV32I.json"))
    }
 }
