using System;
using dpaItextSharp.text;
/*
 * Copyright 2001, 2002 Paulo Soares
 *
 * The contents of this file are subject to the Mozilla Public License Version 1.1
 * (the "License"); you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
 * for the specific language governing rights and limitations under the License.
 *
 * The Original Code is 'iText, a free JAVA-PDF library'.
 *
 * The Initial Developer of the Original Code is Bruno Lowagie. Portions created by
 * the Initial Developer are Copyright (C) 1999, 2000, 2001, 2002 by Bruno Lowagie.
 * All Rights Reserved.
 * Co-Developer of the code is Paulo Soares. Portions created by the Co-Developer
 * are Copyright (C) 2000, 2001, 2002 by Paulo Soares. All Rights Reserved.
 *
 * Contributor(s): all the names of the contributors are added in the source code
 * where applicable.
 *
 * Alternatively, the contents of this file may be used under the terms of the
 * LGPL license (the "GNU LIBRARY GENERAL PUBLIC LICENSE"), in which case the
 * provisions of LGPL are applicable instead of those above.  If you wish to
 * allow use of your version of this file only under the terms of the LGPL
 * License and not to allow others to use your version of this file under
 * the MPL, indicate your decision by deleting the provisions above and
 * replace them with the notice and other provisions required by the LGPL.
 * If you do not delete the provisions above, a recipient may use your version
 * of this file under either the MPL or the GNU LIBRARY GENERAL PUBLIC LICENSE.
 *
 * This library is free software; you can redistribute it and/or modify it
 * under the terms of the MPL as stated above or under the terms of the GNU
 * Library General Public License as published by the Free Software Foundation;
 * either version 2 of the License, or any later version.
 *
 * This library is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the GNU Library general Public License for more
 * details.
 *
 * If you didn't download this code from the following link, you should check if
 * you aren't using an obsolete version:
 * http://www.lowagie.com/iText/
 */

namespace dpaItextSharp.text.pdf {

    /**
    * Implements the form XObject.
    */

    public class PdfTemplate : PdfContentByte {
        public const int TYPE_TEMPLATE = 1;
        public const int TYPE_IMPORTED = 2;
        public const int TYPE_PATTERN = 3;
        protected int type;
        /** The indirect reference to this template */
        protected PdfIndirectReference thisReference;
        
        /** The resources used by this template */
        protected PageResources pageResources;
        
        /** The bounding box of this template */
        protected Rectangle bBox = new Rectangle(0, 0);
        
        protected PdfArray matrix;
        
        protected PdfTransparencyGroup group;
        
        protected IPdfOCG layer;

        /**
        *Creates a <CODE>PdfTemplate</CODE>.
        */
        
        protected PdfTemplate() : base(null) {
            type = TYPE_TEMPLATE;
        }
        
        /**
        * Creates new PdfTemplate
        *
        * @param wr the <CODE>PdfWriter</CODE>
        */
        
        internal PdfTemplate(PdfWriter wr) : base(wr) {
            type = TYPE_TEMPLATE;
            pageResources = new PageResources();
            pageResources.AddDefaultColor(wr.DefaultColorspace);
            thisReference = writer.PdfIndirectReference;
        }
        
        /**
         * Creates a new template.
         * <P>
         * Creates a new template that is nothing more than a form XObject. This template can be included
         * in this <CODE>PdfContentByte</CODE> or in another template. Templates are only written
         * to the output when the document is closed permitting things like showing text in the first page
         * that is only defined in the last page.
         *
         * @param width the bounding box width
         * @param height the bounding box height
         * @return the templated created
         */
        public static PdfTemplate CreateTemplate(PdfWriter writer, float width, float height) {
            return CreateTemplate(writer, width, height, null);
        }
        
        internal static PdfTemplate CreateTemplate(PdfWriter writer, float width, float height, PdfName forcedName) {
            PdfTemplate template = new PdfTemplate(writer);
            template.Width = width;
            template.Height = height;
            writer.AddDirectTemplateSimple(template, forcedName);
            return template;
        }

        /**
        * Gets the bounding width of this template.
        *
        * @return width the bounding width
        */
        public float Width {
            get {
                return bBox.Width;
            }

            set {
                bBox.Left = 0;
                bBox.Right = value;
            }
        }
        
        /**
        * Gets the bounding heigth of this template.
        *
        * @return heigth the bounding height
        */
        
        public float Height {
            get {
                return bBox.Height;
            }

            set {
                bBox.Bottom = 0;
                bBox.Top = value;
            }
        }
        
        public Rectangle BoundingBox {
            get {
                return bBox;
            }
            set {
                this.bBox = value;
            }
        }
        
        /**
        * Gets the layer this template belongs to.
        * @return the layer this template belongs to or <code>null</code> for no layer defined
        */
        public IPdfOCG Layer {
            get {
                return layer;
            }
            set {
                layer = value;
            }
        }

        public void SetMatrix(float a, float b, float c, float d, float e, float f) {
            matrix = new PdfArray();
            matrix.Add(new PdfNumber(a));
            matrix.Add(new PdfNumber(b));
            matrix.Add(new PdfNumber(c));
            matrix.Add(new PdfNumber(d));
            matrix.Add(new PdfNumber(e));
            matrix.Add(new PdfNumber(f));
        }

        internal PdfArray Matrix {
            get {
                return matrix;
            }
        }
        
        /**
        * Gets the indirect reference to this template.
        *
        * @return the indirect reference to this template
        */
        
        public PdfIndirectReference IndirectReference {
            get {
    	        // uncomment the null check as soon as we're sure all examples still work
    	        if (thisReference == null /* && writer != null */) {
    		        thisReference = writer.PdfIndirectReference;
    	        }
                return thisReference;
            }
        }
        
        public void BeginVariableText() {
            content.Append("/Tx BMC ");
        }
        
        public void EndVariableText() {
            content.Append("EMC ");
        }
        
        /**
        * Constructs the resources used by this template.
        *
        * @return the resources used by this template
        */
        
        internal virtual PdfObject Resources {
            get {
                return PageResources.Resources;
            }
        }
        
        /**
        * Gets the stream representing this template.
        *
        * @param   compressionLevel    the compressionLevel
        * @return the stream representing this template
        * @since   2.1.3   (replacing the method without param compressionLevel)
        */
        internal virtual PdfStream GetFormXObject(int compressionLevel) {
            return new PdfFormXObject(this, compressionLevel);
        }
        
        /**
        * Gets a duplicate of this <CODE>PdfTemplate</CODE>. All
        * the members are copied by reference but the buffer stays different.
        * @return a copy of this <CODE>PdfTemplate</CODE>
        */
        
        public override PdfContentByte Duplicate {
            get {
                PdfTemplate tpl = new PdfTemplate();
                tpl.writer = writer;
                tpl.pdf = pdf;
                tpl.thisReference = thisReference;
                tpl.pageResources = pageResources;
                tpl.bBox = new Rectangle(bBox);
                tpl.group = group;
                tpl.layer = layer;
                if (matrix != null) {
                    tpl.matrix = new PdfArray(matrix);
                }
                tpl.separator = separator;
                return tpl;
            }
        }
        
        public int Type {
            get {
                return type;
            }
        }

        internal override PageResources PageResources {
            get {
                return pageResources;
            }
        }
        
        public virtual PdfTransparencyGroup Group {
            get {
                return this.group;
            }
            set {
                group = value;
            }
        }
    }
}