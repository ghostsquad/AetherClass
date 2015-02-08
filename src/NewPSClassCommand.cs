using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Management.Automation;
using System.Management.Automation.Language;
using System.Text;

namespace GravityPS
{
    using System.Linq;

    [Cmdlet(VerbsCommon.New, "PSClass")]
    [OutputType(typeof(PSObject))]
    public class NewPSClassCommand : PSCmdlet
    {
        [Parameter(Position = 0)]
        public string ClassName { get; set; }

        [Parameter(Position = 1)]
        public ScriptBlock Definition { get; set; }

        [Parameter(Position = 2)]
        public PSObject Inherit { get; set; }

        public SwitchParameter PassThru { get; set; }

        protected override void BeginProcessing() {
            base.BeginProcessing();
        }

        protected override void ProcessRecord() {
            base.ProcessRecord();
        }

        protected override void EndProcessing() {
            Token[] tokens = null;
            ParseError[] errors = null;
            var classDefinition = Parser.ParseInput(this.Definition.ToString(), out tokens, out errors);

            // parse error checking needed

            var classDefinitionCommands = this.GetClassDefinitionCommands(classDefinition);
        }

        private IEnumerable<CommandAst> GetClassDefinitionCommands(ScriptBlockAst definitionScriptBlockAst) {
            var commandElements = new string[] { "method", "note", "property", "constructor" };
            var predicate = new Func<Ast, bool>(
                (ast) => {
                    var commandAst = ast as CommandAst;
                    if (commandAst != null && commandAst.CommandElements.Count > 0) {
                        var commandNameStringExpression = commandAst.CommandElements[0] as StringConstantExpressionAst;
                        return commandNameStringExpression != null
                               && commandElements.Contains(commandNameStringExpression.Value);
                    }

                    return false;
                });
            return definitionScriptBlockAst.FindAll(predicate, false).Cast<CommandAst>();
        }
    }
}
