/*
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

'use strict';

const Decorator = require('./introspect/decorator');
const IllegalModelException = require('./introspect/illegalmodelexception');
const ModelUtil = require('./modelutil');

/**
 * Specialised decorator implementation for the @returns decorator.
 */
class ReturnsDecorator extends Decorator {

    /**
     * Create a Decorator.
     * @param {ClassDeclaration | Property} parent - the owner of this property
     * @param {Object} ast - The AST created by the parser
     * @throws {IllegalModelException}
     */
    constructor(parent, ast) {
        super(parent, ast);
    }

    /**
     * Process the AST and build the model
     * @throws {IllegalModelException}
     * @private
     */
    process() {
        super.process();
        const args = this.getArguments();
        if (args.length !== 1) {
            throw new IllegalModelException(`@returns decorator expects 1 argument, but ${args.length} arguments were specified.`, this.parent.getModelFile(), this.ast.location);
        }
        const arg = args[0];
        if (typeof arg !== 'object' || arg.type !== 'Identifier') {
            throw new IllegalModelException(`@returns decorator expects an identifier argument, but an argument of type ${typeof arg} was specified.`, this.parent.getModelFile(), this.ast.location);
        }
        this.type = arg.name;
        this.array = arg.array;
    }

    /**
     * Validate the property
     * @throws {IllegalModelException}
     * @private
     */
    validate() {
        super.validate();
        this.parent.getModelFile().resolveType('@returns decorator.', this.type, this.ast.location);
        this.resolvedType = this.parent.getModelFile().getType(this.type);
    }

    /**
     * Get the type specified in this returns declaration.
     * @returns {string} The type specified in this returns declaration.
     */
    getType() {
        return this.type;
    }

    /**
     * Get the resolved type specified in this returns declaration.
     * @returns {ClassDeclaration} The resolved type specified in this returns declaration.
     */
    getResolvedType() {
        return this.resolvedType;
    }

    /**
     * Returns true if this returns declaration specifies an array type.
     * @returns {boolean} True if this returns declaration specifies an array type.
     */
    isArray() {
        return this.array;
    }

    /**
     * Returns true if this returns declaration specifies a primitive type.
     * @returns {boolean} True if this returns declaration specifies a primitive type.
     */
    isPrimitive() {
        return ModelUtil.isPrimitiveType(this.getType());
    }

    /**
     * Returns true if this returns declaration specifies an enumeration type.
     * @return {boolean} True if this returns declaration specifies an enumeration type.
     */
    isTypeEnum() {
        if(this.isPrimitive()) {
            return false;
        }
        const type = this.getParent().getModelFile().getType(this.getType());
        return type.isEnum();
    }

}

module.exports = ReturnsDecorator;
