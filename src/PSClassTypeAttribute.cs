namespace GpClass {
    using System;

    public class PSClassTypeAttribute : Attribute {
        #region Constructors and Destructors

        public PSClassTypeAttribute(string name) {
            this.Name = name;
        }

        #endregion

        #region Public Properties

        public string Name { get; set; }

        #endregion
    }
}