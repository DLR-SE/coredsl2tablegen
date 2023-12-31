/*
 * generated by Xtext 2.13.0
 */
package de.dlr.coredsl.tablegen

import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.AbstractGenerator
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.generator.IGeneratorContext
import com.minres.coredsl.coreDsl.CoreDef
import com.minres.coredsl.coreDsl.InstructionSet
import org.apache.log4j.Logger
import com.minres.coredsl.coreDsl.Encoding
import com.minres.coredsl.coreDsl.BitField
import com.minres.coredsl.coreDsl.BitValue
import java.util.List
import java.util.ArrayList
import java.util.HashMap
import com.minres.coredsl.coreDsl.ISA
import com.minres.coredsl.util.BigIntegerWithRadix
import com.minres.coredsl.coreDsl.Statement
import org.eclipse.xtext.resource.XtextResource
import java.util.Optional
import java.io.File

/**
 * Generates code from your model files on save.
 *
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#code-generation
 */
class CoreDslTableGenGenerator extends AbstractGenerator
{
    static def dispatch getBitWidth(BitField i)
    {
        return i.left.value.intValue - i.right.value.intValue + 1
    }

    static def dispatch getBitWidth(BitValue i)
    {
        return (i.value as BigIntegerWithRadix).size
    }

    static def dispatch getUpperBitWidth(BitField i)
    {
        return i.left.value.intValue + 1
    }

    static def dispatch getUpperBitWidth(BitValue i)
    {
        return i.bitWidth
    }

    static def dispatch getBitValue(BitField i) '''«i.name»«IF i.right.value.intValue > 0»{«i.left.value»-«i.right.value»}«ENDIF»'''

    static def dispatch getBitValue(BitValue i) '''«IF i.value.equals(java.math.BigInteger.ZERO)»0«ELSE»«(i.value as BigIntegerWithRadix).toCString(2)»«ENDIF»'''

    static class Field
    {
        int bitPosition
        com.minres.coredsl.coreDsl.Field field
        Operand globalOperand
        Operand operand

        def dispatch decodeOperand(BitField field, de.dlr.coredsl.tablegen.Instruction inst, CompilerExtensionYAML yaml, HashMap<String,Field> operands)
        {
            operands.put(field.name, this)
            operand = inst?.operands?.get(field.name)
            globalOperand = yaml?.operands?.get(field.name)
        }

        def dispatch decodeOperand(BitValue value, de.dlr.coredsl.tablegen.Instruction inst, CompilerExtensionYAML yaml, HashMap<String,Field> operands)
        {

        }

        def dispatch getName(BitField field) { return field.name }

        def dispatch getName(BitValue value) { return "" }

        def getName() { return field.name }

        def getBitWidth() { return field.bitWidth }

        def getUpperBitWidth() { return field.getUpperBitWidth }

        def getBitValue() { return field.getBitValue }

        def getIsInput()
        {
            if (operand === null || operand.input === null || !operand.input.isPresent)
            {
                if (globalOperand === null || globalOperand.input === null || !globalOperand.input.isPresent)
                    return false
                else
                    return globalOperand.input.get
            }
            return operand.input.get
        }

        def getIsOutput()
        {
            if (operand === null || operand.output === null || !operand.output.isPresent)
            {
                if (globalOperand === null || globalOperand.output === null || !globalOperand.output.isPresent)
                    return false
                else
                    return globalOperand.output.get
            }
            return operand.output.get
        }

        def getType()
        {
            if (operand === null || operand.type === null || operand.type.isEmpty())
                return globalOperand === null || globalOperand.type === null ? "" : globalOperand.type
            return operand.type
        }

        new(int bp, com.minres.coredsl.coreDsl.Field field, de.dlr.coredsl.tablegen.Instruction inst, CompilerExtensionYAML yaml, HashMap<String,Field> operands)
        {
            this.bitPosition = bp
            this.field = field
            this.field.decodeOperand(inst, yaml, operands)
        }
    }

    static class Instruction
    {
        com.minres.coredsl.coreDsl.Instruction coreInstruction
        de.dlr.coredsl.tablegen.Instruction yamlInstruction
        CompilerExtensionYAML yaml
        ArrayList<Field> encoding

        new(com.minres.coredsl.coreDsl.Instruction ci, CompilerExtensionYAML y, Extension ext)
        {
            yaml = y
            coreInstruction = ci
            ext.yamlExtension = findInstruction(coreInstruction.name)
            var bitPosition = 31
            encoding = new ArrayList<Field>(coreInstruction.encoding.fields.size)
            operands = new HashMap<String,Field>
            for (field : coreInstruction.encoding.fields)
            {
                encoding.add(new Field(bitPosition, field, yamlInstruction, yaml, operands))
                bitPosition -= field.bitWidth
            }
        }

        def getName() { return coreInstruction.name }

        def getCustomInstructionType() { return coreInstruction.customInstructionType }

        def getOptions() { return yamlInstruction as Options }

        def getOperand(String name)
        {
            return operands.get(name)
        }

        def hasArgstringOverride()
        {
            return yamlInstruction != null && yamlInstruction.argstring !== null && !yamlInstruction.argstring.isEmpty
        }

        def getArgstringOverride()
        {
            return yamlInstruction.argstring
        }

        private def findInstruction(String name)
        {
            if (yaml.extensions === null)
                return null
            for (x : yaml.extensions)
            {
                yamlInstruction = x.instructions?.get(name)
                if (yamlInstruction !== null)
                    return x
            }
            return null
        }

        private HashMap<String,Field> operands
    }

    static class RTypeInstruction extends Instruction
    {
        static def inspect(com.minres.coredsl.coreDsl.Instruction instruction)
        {
            if (instruction.encoding.fields.size != 6)
                return false
            var field = instruction.encoding.fields.get(0)
            if (!(field instanceof BitValue) || (field as BitValue).bitWidth != 7)
                return false
            field = instruction.encoding.fields.get(3)
            if (!(field instanceof BitValue) || (field as BitValue).bitWidth != 3)
                return false
            /* True R-Type instructions have rs1, rs2, and rd fields. Some imposters
             * have fixed bit patterns for one or more of these fields
             */
            field = instruction.encoding.fields.get(1)
            if (field instanceof BitValue)
                return false
            field = instruction.encoding.fields.get(2)
            if (field instanceof BitValue)
                return false
            field = instruction.encoding.fields.get(4)
            if (field instanceof BitValue)
                return false
            return true
        }

        new(com.minres.coredsl.coreDsl.Instruction instruction, CompilerExtensionYAML yaml, Extension ext)
        {
            super(instruction, yaml, ext)
        }

        def int getFunct7()
        {
            return (super.encoding.get(0).field as BitValue).value.intValue;
        }

        def int getFunct3()
        {
            return (super.encoding.get(3).field as BitValue).value.intValue;
        }
    }

    static class Extension
    {
        String coreDefName
        de.dlr.coredsl.tablegen.Extension yamlExtension
        HashMap<String,Instruction> instructions

        new (String cn)
        {
            coreDefName = cn
            instructions = new HashMap<String,Instruction>
        }

        def getIdentifier()
        {
            if (yamlExtension !== null && yamlExtension.identifier !== null && !yamlExtension.identifier.isEmpty())
                return yamlExtension.identifier
            return coreDefName
        }

        def getName()
        {
            if (yamlExtension !== null && yamlExtension.identifier !== null && !yamlExtension.name.isEmpty())
                return yamlExtension.name
            return coreDefName
        }

        def getFileName()
        {
            if (yamlExtension !== null && yamlExtension.identifier !== null && !yamlExtension.fileName.isEmpty())
                return yamlExtension.fileName
            return coreDefName
        }

        def hasIntrinsics()
        {
            return yamlExtension !== null && yamlExtension.intrinsics !== null && !yamlExtension.intrinsics.isEmpty
        }

        def getInstructionsFileName()
        {
            return identifier + File.separator + "RISCVInstrInfo_ISAX_" + fileName + ".td"
        }

        def getGCBuiltinFileName()
        {
            return identifier + File.separator + "CGBuiltin.cpp"
        }

        def getBuiltinsRISCVFileName()
        {
            return identifier + File.separator + "BuiltinsRISCV.def"
        }

        def getIntrinsicsRISCVFileName()
        {
            return identifier + File.separator + "IntrinsicsRISCV.td"
        }
    }

    static def analyse(com.minres.coredsl.coreDsl.Instruction instruction, CompilerExtensionYAML yaml, Extension ext)
    {
        if (RTypeInstruction.inspect(instruction))
            return new RTypeInstruction(instruction, yaml, ext)
        else
            return new Instruction(instruction, yaml, ext)
    }

    val logger = Logger.getLogger(typeof(CoreDslTableGenGenerator));

    override void doGenerate(Resource resource, IFileSystemAccess2 fsa, IGeneratorContext context)
    {
        val yaml = (context as YAMLGeneratorContext).yaml
        this.types = yaml.types
        val extensions = new HashMap<String,Extension>
        for (e : resource.allContents.toIterable.filter(InstructionSet))
        for (coreInstruction : e.customInstructions)
        {
            val ext = new Extension(e.name)
            val instruction = analyse(coreInstruction, yaml, ext)
            extensions.merge(ext.identifier, ext, [l,r|l]).instructions.put(instruction.name, instruction)
        }
        extensions.forEach[identifier, ext|
            fsa.generateFile(ext.instructionsFileName, ext.toTableGen(yaml))
            if (ext.hasIntrinsics)
            {
                fsa.generateFile(ext.GCBuiltinFileName, ext.gcbuiltin)
                fsa.generateFile(ext.builtinsRISCVFileName, ext.defBuiltins)
                fsa.generateFile(ext.intrinsicsRISCVFileName, ext.defIntrinsics)
            }
        ]
        fsa.generateFile("extensions.yaml", extensions.values.manifest)
    }

    def Boolean isHls(com.minres.coredsl.coreDsl.Instruction inst)
    {
        val instrSet = inst.eContainer as ISA;
        (inst.attributes.filter[it.type=='hls'].isEmpty &&
        instrSet.commonInstructionAttributes.filter[it.type=='hls'].isEmpty)
    }

    static def int customInstructionType(com.minres.coredsl.coreDsl.Instruction inst)
    {
        val opCode = inst.encoding.fields.get(inst.encoding.fields.size-1)
        if (!(opCode instanceof BitValue))
            return -1
        val bits = (opCode as BitValue).value
        if (bits.bitLength > 7)
            return -1
        switch (bits.intValue)
        {
        case /*0b0001011*/ 11:
            return 0
        case /*0b0101011*/ 43:
            return 1
        case /*0b1011011*/ 91:
            return 2
        case /*0b1111011*/ 123:
            return 3
        default:
            return -1
        }
    }

    static def Boolean isCustomInstruction(com.minres.coredsl.coreDsl.Instruction inst)
    {
        return customInstructionType(inst) != -1
    }

    def outs(Instruction inst) '''(outs«FOR o : inst.encoding.reverseView.filter[it.isOutput] BEFORE ' ' SEPARATOR ', '»«o.type»:$«o.name»«ENDFOR»)'''

    def ins(Instruction inst) '''(ins«FOR o : inst.encoding.reverseView.filter[it.isInput] BEFORE ' ' SEPARATOR ', '»«o.type»:$«o.name»«IF o.isOutput»i«ENDIF»«ENDFOR»)'''

    def registers(Instruction inst) '''«FOR o : inst.encoding.reverseView.filter[it.field instanceof BitField] SEPARATOR ', '»$«o.name»«ENDFOR»'''

    def argstring(Instruction inst) '''«IF inst.hasArgstringOverride»«inst.argstringOverride»«ELSE»«inst.registers»«ENDIF»'''

    def constraints(Instruction inst) '''«FOR o : inst.encoding.reverseView.filter[it.isInput && it.isOutput] BEFORE '\n  let Constraints = "' SEPARATOR ', ' AFTER '";\n'»$«o.name» = $«o.name»i«ENDFOR»'''

    def dispatch toTableGen(RTypeInstruction inst) '''def «inst.name» : RVInstR<«inst.funct7», «inst.funct3», OPC_CUSTOM_«inst.customInstructionType», «inst.outs», «inst.ins», "«inst.name.toLowerCase»", "«inst.argstring»">, Sched<[]> {«inst.options.toTableGen»«inst.constraints»
}'''

    def dispatch toTableGen(Instruction inst) '''def «inst.name» : RVInst<«inst.outs», «inst.ins», "«inst.name.toLowerCase»", "«inst.argstring»", [], InstFormatOther>, Sched<[]> {
  «FOR o : inst.encoding.reverseView.filter[it.field instanceof BitField]»
  bits<«o.upperBitWidth»> «o.name»;
«ENDFOR»
  «FOR f : inst.encoding.filter[it.bitPosition != 6]»
  let Inst{«f.bitPosition»«IF f.bitWidth > 1»-«f.bitPosition - f.bitWidth + 1»«ENDIF»} = «f.bitValue»;
«ENDFOR»
  let Opcode = OPC_CUSTOM_«inst.customInstructionType».Value;«inst.options.toTableGen»«inst.constraints»
}'''

    def Boolean defined(java.lang.reflect.Field field, Options options)
    {
        return options !== null && field.get(options) !== null
    }

    def dispatch tdBool(java.lang.reflect.Field field, Options options) '''«(field.get(options) as Optional<Boolean>).tdBool»'''

    def dispatch tdBool(Optional<Boolean> b) '''«b.get().tdBool»'''

    def dispatch tdBool(Boolean b) '''«IF b»1«ELSE»0«ENDIF»'''

    def dispatch toTableGen(Options yaml) '''«FOR option : typeof(Options).fields.filter[it.defined(yaml)] BEFORE '\n' AFTER '\n'»
  let «option.name» = «option.tdBool(yaml)»;«ENDFOR»'''

    def dispatch toTableGen(Void v) ''''''

    def globalOptions(CompilerExtensionYAML yaml) '''«FOR option : typeof(Options).fields.filter[it.defined(yaml.options)] SEPARATOR ', '»«option.name» = «option.tdBool(yaml.options)»«ENDFOR»'''

    def getIdentifier(java.util.Map.Entry<String,Intrinsic> intr) '''int_riscv_«intr.key.toLowerCase»'''

    def getInstructionName(java.util.Map.Entry<String,Intrinsic> intr)
    {
        if (intr.value !== null && intr.value.instruction !== null && !intr.value.instruction.isEmpty)
            return intr.value.instruction
        return intr.key
    }

    def getOperandName(Parameter p)
    {
        if (p.operand === null || p.operand.isEmpty)
            return p.name
        return p.operand
    }

    def getPatternType(Parameter p, Field f)
    {
        if (p.type !== null && !p.type.isEmpty)
        {
            val t = types.get(p.type)
            if (t !== null && t.ice && t.cType !== null && !t.cType.isEmpty)
                return t.cType
        }
        return f?.type
    }

    def getParameter(Intrinsic intr, Field f)
    {
        if (intr === null || intr.parameters === null)
            return null
        val name = f.name
        for (p : intr.parameters)
            if (p.operandName == name)
                return p
        return null
    }

    def toTableGen(Parameter p, Field f) '''
        «p.getPatternType(f)»:$«p.name»'''

    def parameters(Intrinsic intr, Instruction inst) '''
        «IF intr !== null && intr.parameters !== null»
        «FOR p : intr.parameters BEFORE ' ' SEPARATOR ', '»
        «p.toTableGen(inst.getOperand(p.operandName))»«ENDFOR»«ENDIF»'''

    def arguments(Instruction inst, Intrinsic intr) '''
        «IF intr !== null && intr.parameters !== null»
        «FOR o : inst.encoding.reverseView.filter[it.isInput] BEFORE ' ' SEPARATOR ', '»
        «intr.getParameter(o).toTableGen(o)»«ENDFOR»«ENDIF»'''

    def pattern(java.util.Map.Entry<String,Intrinsic> intr, Instruction inst) '''
        class Pat_«inst.name»<SDPatternOperator OpNode, RVInst Inst>
            : Pat<(OpNode«intr.value.parameters(inst)»),(Inst«inst.arguments(intr.value)»)>;
        def : Pat_«inst.name»<«intr.identifier», «inst.name»>;'''

    def CharSequence toTableGen(Extension ext, CompilerExtensionYAML yaml) '''//===-- RISCV custom instructions (ISAX) for «ext.name» ---*- tablegen -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file describes the experimental extension for «ext.name» RISC-V instructions.
//
//===----------------------------------------------------------------------===//

let Predicates = [HasCustExt«ext.identifier»] in {

let «yaml.globalOptions» in {

    «FOR inst : ext.instructions.values»
«inst.toTableGen»

«ENDFOR»
}
«IF ext.yamlExtension?.intrinsics?.entrySet !== null»«FOR intr : ext.yamlExtension.intrinsics.entrySet»

«intr.pattern(ext.instructions.get(intr.instructionName))»
«ENDFOR»«ENDIF»

}'''

    // this is just for fixing indention
    def nothing() {return ""}

    def CharSequence gcbuiltin(Extension ext)
    '''  // «ext.name»«FOR intr : ext.yamlExtension.intrinsics.keySet»
         case RISCV::BI__builtin_x«ext.identifier»_«intr.toLowerCase»:
           ID = Intrinsic::riscv_«intr.toLowerCase»;
           break;
    «ENDFOR»'''

    def getFType(String typeName)
    {
        if (typeName === null || typeName.isEmpty)
            return ""
        val t = types.get(typeName)
        if (t === null || t.fType === null)
            return ""
        return t.fType
    }

    def functionType(java.util.Map.Entry<String,Intrinsic> intr) '''«IF intr.value !== null»
        «intr.value.returnType.getFType»«IF intr.value.parameters !== null»«FOR p : intr.value.parameters»«p.type.getFType»«ENDFOR»«ENDIF»«ENDIF»'''

    def CharSequence defBuiltins(Extension ext) '''
        // «ext.name» extension«FOR intr : ext.yamlExtension.intrinsics.entrySet»
        TARGET_BUILTIN(__builtin_x«ext.identifier»_«intr.key.toLowerCase», "«intr.functionType»", "nc", "x«ext.identifier»")
    «ENDFOR»'''

    def getCType(String typeName)
    {
        if (typeName === null || typeName.isEmpty)
            return ""
        val t = types.get(typeName)
        if (t === null || t.cType === null)
            return ""
        return "llvm_" + t.cType + "_ty"
    }

    def CharSequence defIntrinsics(Extension ext) '''
        let TargetPrefix = "riscv" in {«FOR intr : ext.yamlExtension.intrinsics.entrySet»

        «nothing»
          def «intr.identifier» : Intrinsic<
             [«intr.value.returnType.getCType»],
             [«IF intr.value.parameters !== null»«FOR p : intr.value.parameters SEPARATOR ', '»«p.type.getCType»«ENDFOR»«ENDIF»],
             [IntrNoMem, IntrSpeculatable, IntrWillReturn]>;«ENDFOR»
        }'''

    def CharSequence manifest(Iterable<Extension> extensions) '''
        «FOR ext : extensions SEPARATOR '\n'»
        - name: «ext.identifier»
          description: «ext.name»
          instructions: «ext.instructionsFileName»«IF ext.hasIntrinsics»
              BuiltinsRISCV.def: «ext.builtinsRISCVFileName»
              CGBuiltin.cpp: «ext.GCBuiltinFileName»
              IntrinsicsRISCV.td: «ext.intrinsicsRISCVFileName»«ENDIF»«ENDFOR»'''

    def String getSource(Statement stmt)
    {
        (stmt.eResource as XtextResource).serializer.serialize(stmt)
    }

    def Iterable<com.minres.coredsl.coreDsl.Instruction> allInstr(InstructionSet core)
    {
        val unique = newLinkedHashMap
        val instrList = core.instructions
//            if (core.contributingType.size == 0)
//            {
//                core.instructions
//            }
//            else
//            {
//                val instrSets = core.contributingType?.map[InstructionSet i|i.allInstructionSets].flatten
//                val seen = newLinkedHashSet
//                seen.addAll(instrSets)
//                seen.map[InstructionSet i|i.instructions].flatten
//            }
        for (com.minres.coredsl.coreDsl.Instruction i : instrList)
        {
            if (i.eContainer instanceof InstructionSet)
                logger.trace("adding instruction " + i.name + " of " + (i.eContainer as InstructionSet).name)
            if (i.eContainer instanceof CoreDef)
                logger.trace("adding instruction " + i.name + " of " + (i.eContainer as CoreDef).name)
            unique.put(i.name, i)
        }
        val instLut = newLinkedHashMap()
        for (com.minres.coredsl.coreDsl.Instruction i : unique.values)
        {
            logger.trace("adding encoding " + i.encoding.bitEncoding + " for instruction " + i.name)
            instLut.put(i.encoding.bitEncoding, i)
        }
        return instLut.values
    }

    def List<InstructionSet> allInstructionSets(InstructionSet core)
    {
        val s = if(core.superType !== null) core.superType.allInstructionSets else newLinkedList
        s.add(core)
        return s
    }

    def customInstructions(InstructionSet instrSet)
    {
        return instrSet.allInstr.filter[it.isCustomInstruction]
    }

    def String getBitEncoding(Encoding encoding) '''«FOR field : encoding.fields»«field.regEx»«ENDFOR»'''

    def dispatch getRegEx(BitField i) '''«FOR idx : i.right.value.intValue .. i.left.value.intValue».«ENDFOR»'''

    def dispatch getRegEx(BitValue i) '''«i.value.toString(2)»'''

    def dispatch asString(BitField i) '''«i.name»[«i.left.value.intValue»:«i.right.value.intValue»]'''

    def dispatch asString(BitValue i)
    {
        (i.value as BigIntegerWithRadix).toCString(2)
    }

    private HashMap<String,Type> types
}
