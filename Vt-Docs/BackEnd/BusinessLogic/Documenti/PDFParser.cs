﻿using System;
using System.IO;
using iTextSharp.text.pdf;
using System.Linq;
using System.Collections.Generic;

namespace PdfToText
{
    /// <summary>
    /// Parses a PDF file and extracts the text from it.
    /// </summary>
    public class PDFParser
    {
        /// BT = Beginning of a text object operator 
        /// ET = End of a text object operator
        /// Td move to the start of next line
        ///  5 Ts = superscript
        /// -5 Ts = subscript
        #region Fields

        #region _numberOfCharsToKeep
        /// <summary>
        /// The number of characters to keep, when extracting text.
        /// </summary>
        private static int _numberOfCharsToKeep = 15;
        #endregion

        #endregion

        #region ExtractWords

        public string JoinStringArray(string[] strings)
        {
            string retval =string.Empty;
            foreach (string s in strings)
                retval += s + " ";

            return retval;
        }

        public string[] ExtractWordsFromPDF(byte[] pdfFile)
        {
            //con le versioni piu recenti di itextsharp di puo' usare il codice commentato.

            /*
            iTextSharp.text.pdf.PdfReader reader = new iTextSharp.text.pdf.PdfReader(pdfFile);
            StringWriter output = new StringWriter();
           
            iTextSharp.text.pdf.parser.SimpleTextExtractionStrategy strategy = new  iTextSharp.text.pdf.parser.SimpleTextExtractionStrategy();
            for (int i = 1; i <= reader.NumberOfPages; i++)
                output.WriteLine(iTextSharp.text.pdf.parser.PdfTextExtractor.GetTextFromPage(reader, i, strategy));
            /
            PDFParser p = new PDFParser();
            p.ExtractText (
           /*
            for (int i = 1; i <= reader.NumberOfPages; i++)
                output.WriteLine(iTextSharp.text.pdf.parser.PdfTextExtractor.GetTextFromPage(reader, i, new iTextSharp.text.pdf.parser.SimpleTextExtractionStrategy()));
            */
            //string retval = output.ToString();

            string retval =  ExtractText(pdfFile);

            retval = retval.Replace("\r", "").Replace("\n", "").Replace(".", "").Replace(",", "").Replace(";", "").Replace(":", "").Replace(")", "").Replace("(", "").Replace("/", "");
            string[] arr = retval.Split(' ');

            List<string> words = (from a in arr where a.Trim().Length > 3 select a.Trim()).Distinct().ToList<string>();
            return words.ToArray();
        }

        #endregion

        #region ExtractText

        public string  ExtractText(byte[] pdfContent)
        {
            StringWriter output = new StringWriter();
             try
             {
                 // Create a reader for the given PDF file
                 PdfReader reader = new PdfReader(pdfContent);
                 //outFile = File.CreateText(outFileName);
                for (int page = 1; page <= reader.NumberOfPages; page++)
                    output.Write(ExtractTextFromPDFBytes(reader.GetPageContent(page)) + " ");
            }
            catch
            {
                
            }
            return output.ToString();
        }

        /// <summary>
        /// Extracts a text from a PDF file.
        /// </summary>
        /// <param name="inFileName">the full path to the pdf file.</param>
        /// <param name="outFileName">the output file name.</param>
        /// <returns>the extracted text</returns>
        public bool ExtractText(string inFileName, string outFileName)
        {
            StreamWriter outFile = null;
            try
            {
                // Create a reader for the given PDF file
                PdfReader reader = new PdfReader(inFileName);
                //outFile = File.CreateText(outFileName);
                outFile = new StreamWriter(outFileName, false, System.Text.Encoding.UTF8);



                for (int page = 1; page <= reader.NumberOfPages; page++)
                {
                    outFile.Write(ExtractTextFromPDFBytes(reader.GetPageContent(page)) + " ");

                }

                return true;
            }
            catch
            {
                return false;
            }
            finally
            {
                if (outFile != null) outFile.Close();
            }
        }
        #endregion

        #region ExtractTextFromPDFBytes
        /// <summary>
        /// This method processes an uncompressed Adobe (text) object 
        /// and extracts text.
        /// </summary>
        /// <param name="input">uncompressed</param>
        /// <returns></returns>
        private string ExtractTextFromPDFBytes(byte[] input)
        {
            if (input == null || input.Length == 0) return "";

            try
            {
                string resultString = "";

                // Flag showing if we are we currently inside a text object
                bool inTextObject = false;

                // Flag showing if the next character is literal 
                // e.g. '\\' to get a '\' character or '\(' to get '('
                bool nextLiteral = false;

                // () Bracket nesting level. Text appears inside ()
                int bracketDepth = 0;

                // Keep previous chars to get extract numbers etc.:
                char[] previousCharacters = new char[_numberOfCharsToKeep];
                for (int j = 0; j < _numberOfCharsToKeep; j++) previousCharacters[j] = ' ';


                for (int i = 0; i < input.Length; i++)
                {
                    char c = (char)input[i];

                    if (inTextObject)
                    {
                        // Position the text
                        if (bracketDepth == 0)
                        {
                            if (CheckToken(new string[] { "TD", "Td" }, previousCharacters))
                            {
                                resultString += "\n\r";
                            }
                            else
                            {
                                if (CheckToken(new string[] { "'", "T*", "\"" }, previousCharacters))
                                {
                                    resultString += "\n";
                                }
                                else
                                {
                                    if (CheckToken(new string[] { "Tj" }, previousCharacters))
                                    {
                                        resultString += " ";
                                    }
                                }
                            }
                        }

                        // End of a text object, also go to a new line.
                        if (bracketDepth == 0 &&
                            CheckToken(new string[] { "ET" }, previousCharacters))
                        {

                            inTextObject = false;
                            resultString += " ";
                        }
                        else
                        {
                            // Start outputting text
                            if ((c == '(') && (bracketDepth == 0) && (!nextLiteral))
                            {
                                bracketDepth = 1;
                            }
                            else
                            {
                                // Stop outputting text
                                if ((c == ')') && (bracketDepth == 1) && (!nextLiteral))
                                {
                                    bracketDepth = 0;
                                }
                                else
                                {
                                    // Just a normal text character:
                                    if (bracketDepth == 1)
                                    {
                                        // Only print out next character no matter what. 
                                        // Do not interpret.
                                        if (c == '\\' && !nextLiteral)
                                        {
                                            nextLiteral = true;
                                        }
                                        else
                                        {
                                            if (((c >= ' ') && (c <= '~')) ||
                                                ((c >= 128) && (c < 255)))
                                            {
                                                resultString += c.ToString();
                                            }

                                            nextLiteral = false;
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Store the recent characters for 
                    // when we have to go back for a checking
                    for (int j = 0; j < _numberOfCharsToKeep - 1; j++)
                    {
                        previousCharacters[j] = previousCharacters[j + 1];
                    }
                    previousCharacters[_numberOfCharsToKeep - 1] = c;

                    // Start of a text object
                    if (!inTextObject && CheckToken(new string[] { "BT" }, previousCharacters))
                    {
                        inTextObject = true;
                    }
                }
                return resultString;
            }
            catch
            {
                return "";
            }
        }
        #endregion

        #region CheckToken
        /// <summary>
        /// Check if a certain 2 character token just came along (e.g. BT)
        /// </summary>
        /// <param name="search">the searched token</param>
        /// <param name="recent">the recent character array</param>
        /// <returns></returns>
        private bool CheckToken(string[] tokens, char[] recent)
        {
            try
            {
                foreach (string token in tokens)
                {
                    if ((recent[_numberOfCharsToKeep - 3] == token[0]) &&
                        (recent[_numberOfCharsToKeep - 2] == token[1]) &&
                        ((recent[_numberOfCharsToKeep - 1] == ' ') ||
                        (recent[_numberOfCharsToKeep - 1] == 0x0d) ||
                        (recent[_numberOfCharsToKeep - 1] == 0x0a)) &&
                        ((recent[_numberOfCharsToKeep - 4] == ' ') ||
                        (recent[_numberOfCharsToKeep - 4] == 0x0d) ||
                        (recent[_numberOfCharsToKeep - 4] == 0x0a))
                        )
                    {
                        return true;
                    }
                }
            } catch 
            {
                return false;
            }
            return false;
        }
        #endregion
    }
}