package de.dlr.coredsl.tablegen

import java.util.HashMap
import java.util.ArrayList
import java.io.File
import java.util.Optional
import com.fasterxml.jackson.databind.ObjectMapper
import com.fasterxml.jackson.dataformat.yaml.YAMLFactory
import com.fasterxml.jackson.datatype.jdk8.Jdk8Module

class Operand {
    public Optional<Boolean> input
    public Optional<Boolean> output
    public String type

    def merge(Operand other) {
        if (other === null)
            return;
        other.input.ifPresent[x|input = Optional.of(x)]
        other.output.ifPresent[x|output = Optional.of(x)]
        if (!other.type.isEmpty())
            type = other.type
    }
}

class Options {
    public Optional<Boolean> mayLoad
    public Optional<Boolean> mayStore
    public Optional<Boolean> hasSideEffects
    public Optional<Boolean> isBranch
    public Optional<Boolean> isTerminator

    def merge(Options other) {
        if (other === null)
            return;
        other.mayLoad.ifPresent([x|mayLoad = Optional.of(x)])
        other.mayStore.ifPresent([x|mayStore = Optional.of(x)])
        other.hasSideEffects.ifPresent([x|hasSideEffects = Optional.of(x)])
        other.isBranch.ifPresent([x|isBranch = Optional.of(x)])
        other.isTerminator.ifPresent([x|isTerminator = Optional.of(x)])
    }
}

class Instruction extends Options {
    public HashMap<String,Operand> operands
    public String argstring

    def merge(Instruction other) {
        if (other === null)
            return;
        super.merge(other)
        if (operands !== null)
            other.operands?.forEach[key, value | operands.merge(key, value, [x,y|x.merge(y) x])]
        else
            operands = other.operands
        if (argstring === null || argstring.isEmpty)
            argstring = other.argstring
    }
}

class Type {
    public String cType
    public String fType
    public boolean ice = false

    def merge(Type other) {
        if (other === null)
            return;
        // TODO
    }
}

class Parameter {
    public String name
    public String type
    public String operand
}

class Intrinsic {
    public String instruction
    public String returnType
    public ArrayList<Parameter> parameters

    def merge(Intrinsic other) {
        if (other === null)
            return;
        // TODO
    }
}

class Extension {
    public String name
    public String identifier
    public String fileName
    public HashMap<String,Instruction> instructions
    public HashMap<String,Intrinsic> intrinsics

    def merge(Extension other) {
        if (other === null)
            return;
        if (instructions !== null)
            other.instructions?.forEach[key, value | instructions.merge(key, value, [x,y|x.merge(y) x])]
        else
            instructions = other.instructions
        if (intrinsics !== null)
            other.intrinsics?.forEach[key, value | intrinsics.merge(key, value, [x,y|x.merge(y) x])]
        else
            intrinsics = other.intrinsics
    }
}

class CompilerExtensionYAML {
    def static parse(File YAMLInput) {
        val mapper = new ObjectMapper(new YAMLFactory())
        mapper.registerModule(new Jdk8Module())
        return mapper.readValue(YAMLInput, typeof(CompilerExtensionYAML))
    }

    public Options options
    public HashMap<String,Type> types
    public HashMap<String,Operand> operands
    public ArrayList<Extension> extensions

    def merge(CompilerExtensionYAML other) {
        if (other === null)
            return;
        if (options !== null)
            options.merge(other.options)
        else
            options = other.options
        if (types !== null)
            other.types?.forEach[key, value | types.merge(key, value, [x,y|x.merge(y) x])]
        else
            types = other.types
        if (operands !== null)
            other.operands?.forEach[key, value | operands.merge(key, value, [x,y|x.merge(y) x])]
        else
            operands = other.operands
        if (extensions !== null)
            other.extensions?.forEach[e|
                extensions.add(e) // TODO: merge existing extension definition or throw error etc.
            ]
        else
            extensions = other.extensions
    }
}
