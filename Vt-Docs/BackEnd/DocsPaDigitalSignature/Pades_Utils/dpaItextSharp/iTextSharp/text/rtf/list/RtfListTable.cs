using System;
using System.IO;
using System.Collections;
using dpaItextSharp.text;
using dpaItextSharp.text.rtf;
using dpaItextSharp.text.rtf.document;
/*
 * $Id: RtfListTable.cs,v 1.6 2008/05/16 19:31:04 psoares33 Exp $
 * 
 *
 * Copyright 2001, 2002, 2003, 2004 by Mark Hall
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
 * LGPL license (the ?GNU LIBRARY GENERAL PUBLIC LICENSE?), in which case the
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

namespace dpaItextSharp.text.rtf.list {

    /**
    * The RtfListTable manages all RtfLists in one RtfDocument. It also generates
    * the list and list override tables in the document header.
    * 
    * @version $Version:$
    * @author Mark Hall (Mark.Hall@mail.room3b.eu)
    */
    public class RtfListTable : RtfElement, IRtfExtendedElement {

        /**
        * Constant for the list table
        */
        private static byte[] LIST_TABLE = DocWriter.GetISOBytes("\\*\\listtable");
        /**
        * Constant for the list override table
        */
        private static byte[] LIST_OVERRIDE_TABLE = DocWriter.GetISOBytes("\\*\\listoverridetable");
        /**
        * Constant for the list override
        */
        private static byte[] LIST_OVERRIDE = DocWriter.GetISOBytes("\\listoverride");
        /**
        * Constant for the list override count
        */
        private static byte[] LIST_OVERRIDE_COUNT = DocWriter.GetISOBytes("\\listoverridecount");
        
        /**
        * The RtfLists managed by this RtfListTable
        */
        private ArrayList lists;
        
        /**
        * The RtfPictureList lists managed by this RtfListTable
        */
        private ArrayList picturelists;

        /**
        * Constructs a RtfListTable for a RtfDocument
        * 
        * @param doc The RtfDocument this RtfListTable belongs to
        */
        public RtfListTable(RtfDocument doc) : base(doc) {
            this.lists = new ArrayList();
            this.picturelists = new ArrayList();
        }

        /**
        * unused
        */
        public override void WriteContent(Stream outp) {       
        }
        
        /**
        * Writes the list and list override tables.
        */
        public virtual void WriteDefinition(Stream result) {
            byte[] t;
            result.Write(OPEN_GROUP, 0, OPEN_GROUP.Length);
            result.Write(LIST_TABLE, 0, LIST_TABLE.Length);
            this.document.OutputDebugLinebreak(result);
            
            for (int i = 0; i < picturelists.Count; i++) {
                RtfPictureList l = (RtfPictureList)picturelists[i];
    //          l.SetID(document.GetRandomInt());
                l.WriteDefinition(result);
                this.document.OutputDebugLinebreak(result);
            }

            for (int i = 0; i < lists.Count; i++) {
                RtfList l = (RtfList)lists[i];
                l.SetID(document.GetRandomInt());
                l.WriteDefinition(result);
                this.document.OutputDebugLinebreak(result);
            }
            result.Write(CLOSE_GROUP, 0, CLOSE_GROUP.Length);
            this.document.OutputDebugLinebreak(result);
            
            result.Write(OPEN_GROUP, 0, OPEN_GROUP.Length);
            result.Write(LIST_OVERRIDE_TABLE, 0, LIST_OVERRIDE_TABLE.Length);
            this.document.OutputDebugLinebreak(result);
            
            // list override index values are 1-based, not 0.
            // valid list override index values \ls are 1 to 2000.
            // if there are more then 2000 lists, the result is undefined.
            for (int i = 0; i < lists.Count; i++) {
                result.Write(OPEN_GROUP, 0, OPEN_GROUP.Length);
                result.Write(LIST_OVERRIDE, 0, LIST_OVERRIDE.Length);
                result.Write(RtfList.LIST_ID, 0, RtfList.LIST_ID.Length);
                result.Write(t = IntToByteArray( ((RtfList) lists[i]).GetID() ), 0, t.Length);
                result.Write(LIST_OVERRIDE_COUNT, 0, LIST_OVERRIDE_COUNT.Length);
                result.Write(t = IntToByteArray(0), 0, t.Length);    // is this correct? Spec says valid values are 1 or 9.
                result.Write(RtfList.LIST_NUMBER, 0, RtfList.LIST_NUMBER.Length);
                result.Write(t = IntToByteArray( ((RtfList) lists[i]).GetListNumber()) , 0, t.Length);
                result.Write(CLOSE_GROUP, 0, CLOSE_GROUP.Length);
                this.document.OutputDebugLinebreak(result);
            }
            result.Write(CLOSE_GROUP, 0, CLOSE_GROUP.Length);
            this.document.OutputDebugLinebreak(result);
        }

        /**
        * Gets the id of the specified RtfList. If the RtfList is not yet in the
        * list of RtfLists, then it is added.
        * 
        * @param list The RtfList for which to get the id.
        * @return The id of the RtfList.
        */
        public int GetListNumber(RtfList list) {
            if (lists.Contains(list)) {
                return lists.IndexOf(list);
            } else {
                lists.Add(list);
                return lists.Count;
            }
        }
        
        /**
        * Remove a RtfList from the list of RtfLists
        * 
        * @param list The RtfList to remove.
        */
        public void FreeListNumber(RtfList list) {
            int i = lists.IndexOf(list);
            if (i >= 0) {
                lists.RemoveAt(i);
            }
        }
    }
}