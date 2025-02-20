﻿using System;
using System.Collections;
using System.Globalization;
using System.IO;
using log4net.Util;
using log4net.Core;
using log4net.Appender;
using System.Reflection;

namespace NttDataWA.Utils
{
    /// <summary>
    /// Appender that rolls log files based on size or date or both.
    /// </summary>
    /// <remarks>
    /// <para>
    /// RollingFileAppender can roll log files based on size or date or both
    /// depending on the setting of the <see cref="RollingStyle"/> property.
    /// When set to <see cref="RollingMode.Size"/> the log file will be rolled
    /// once its size exceeds the <see cref="MaximumFileSize"/>.
    /// When set to <see cref="RollingMode.Date"/> the log file will be rolled
    /// once the date boundary specified in the <see cref="DatePattern"/> property
    /// is crossed.
    /// When set to <see cref="RollingMode.Composite"/> the log file will be
    /// rolled once the date boundary specified in the <see cref="DatePattern"/> property
    /// is crossed, but within a date boundary the file will also be rolled
    /// once its size exceeds the <see cref="MaximumFileSize"/>.
    /// When set to <see cref="RollingMode.Once"/> the log file will be rolled when
    /// the appender is configured. This effectively means that the log file can be
    /// rolled once per program execution.
    /// </para>
    /// <para>
    /// A of few additional optional features have been added:
    /// <list type="bullet">
    /// <item>Attach date pattern for current log file <see cref="StaticLogFileName"/></item>
    /// <item>Backup number increments for newer files <see cref="CountDirection"/></item>
    /// <item>Infinite number of backups by file size <see cref="MaxSizeRollBackups"/></item>
    /// </list>
    /// </para>
    /// 
    /// <note>
    /// <para>
    /// For large or infinite numbers of backup files a <see cref="CountDirection"/> 
    /// greater than zero is highly recommended, otherwise all the backup files need
    /// to be renamed each time a new backup is created.
    /// </para>
    /// <para>
    /// When Date/Time based rolling is used setting <see cref="StaticLogFileName"/> 
    /// to <see langword="true"/> will reduce the number of file renamings to few or none.
    /// </para>
    /// </note>
    /// 
    /// <note type="caution">
    /// <para>
    /// Changing <see cref="StaticLogFileName"/> or <see cref="CountDirection"/> without clearing
    /// the log file directory of backup files will cause unexpected and unwanted side effects.  
    /// </para>
    /// </note>
    /// 
    /// <para>
    /// If Date/Time based rolling is enabled this appender will attempt to roll existing files
    /// in the directory without a Date/Time tag based on the last write date of the base log file.
    /// The appender only rolls the log file when a message is logged. If Date/Time based rolling 
    /// is enabled then the appender will not roll the log file at the Date/Time boundary but
    /// at the point when the next message is logged after the boundary has been crossed.
    /// </para>
    /// 
    /// <para>
    /// The <see cref="RollingFileAppender"/> extends the <see cref="FileAppender"/> and
    /// has the same behavior when opening the log file.
    /// The appender will first try to open the file for writing when <see cref="ActivateOptions"/>
    /// is called. This will typically be during configuration.
    /// If the file cannot be opened for writing the appender will attempt
    /// to open the file again each time a message is logged to the appender.
    /// If the file cannot be opened for writing when a message is logged then
    /// the message will be discarded by this appender.
    /// </para>
    /// <para>
    /// When rolling a backup file necessitates deleting an older backup file the
    /// file to be deleted is moved to a temporary name before being deleted.
    /// </para>
    /// 
    /// <note type="caution">
    /// <para>
    /// A maximum number of backup files when rolling on date/time boundaries is not supported.
    /// </para>
    /// </note>
    /// </remarks>
    /// <author>Nicko Cadell</author>
    /// <author>Gert Driesen</author>
    /// <author>Aspi Havewala</author>
    /// <author>Douglas de la Torre</author>
    /// <author>Edward Smit</author>
    public class DateTimeRollingFileAppender : FileAppender
    {

        #region Protected Enums

        /// <summary>
        /// The code assumes that the following 'time' constants are in a increasing sequence.
        /// </summary>
        /// <remarks>
        /// <para>
        /// The code assumes that the following 'time' constants are in a increasing sequence.
        /// </para>
        /// </remarks>
        protected enum RollPoint
        {
            /// <summary>
            /// Roll the log not based on the date
            /// </summary>
            InvalidRollPoint = -1,

            /// <summary>
            /// Roll the log for each minute
            /// </summary>
            TopOfMinute = 0,

            /// <summary>
            /// Roll the log for each hour
            /// </summary>
            TopOfHour = 1,

            /// <summary>
            /// Roll the log twice a day (midday and midnight)
            /// </summary>
            HalfDay = 2,

            /// <summary>
            /// Roll the log each day (midnight)
            /// </summary>
            TopOfDay = 3,

            /// <summary>
            /// Roll the log each week
            /// </summary>
            TopOfWeek = 4,

            /// <summary>
            /// Roll the log each month
            /// </summary>
            TopOfMonth = 5
        }

        #endregion Protected Enums

        #region Public Instance Constructors

        /// <summary>
        /// Initializes a new instance of the <see cref="RollingFileAppender" /> class.
        /// </summary>
        /// <remarks>
        /// <para>
        /// Default constructor.
        /// </para>
        /// </remarks>
        public DateTimeRollingFileAppender()
        {
            m_dateTime = new DefaultDateTime();
            m_rollDate = true;
            m_rollSize = false;
            this.ServerName = String.Empty;
        }

        #endregion Public Instance Constructors

        #region Public Instance Properties

        public override string File
        {
            get
            {
                // Costruzione del path del file
                String filePath = String.Empty;

                // Viene sostiutuito l'eventuale segnaposto %COMPUTERNAME con il valore della
                // proprietà ComputerName
                filePath = _handlerInstance.FilePath.Replace("%SERVERNAME", this.ServerName);

                return filePath + "//" + _handlerInstance.FileName;
            }
            set
            {
            }
        }

        /// <summary>
        /// Nome del pc in cui è stato prodotto il log.
        /// Per utilizzarla, creare un param simile al seguente nella configurazione dell'appender (Web.config)
        /// &lt; param name="ComputerName" value="${COMPUTERNAME}" /&gt;
        /// </summary>
        public String ServerName { get; set; }


        /// <summary>
        /// Gets or sets the maximum number of backup files that are kept before
        /// the oldest is erased.
        /// </summary>
        /// <value>
        /// The maximum number of backup files that are kept before the oldest is
        /// erased.
        /// </value>
        /// <remarks>
        /// <para>
        /// If set to zero, then there will be no backup files and the log file 
        /// will be truncated when it reaches <see cref="MaxFileSize"/>.  
        /// </para>
        /// <para>
        /// If a negative number is supplied then no deletions will be made.  Note 
        /// that this could result in very slow performance as a large number of 
        /// files are rolled over unless <see cref="CountDirection"/> is used.
        /// </para>
        /// <para>
        /// The maximum applies to <b>each</b> time based group of files and 
        /// <b>not</b> the total.
        /// </para>
        /// </remarks>
        public int MaxSizeRollBackups
        {
            get { return m_maxSizeRollBackups; }
            set { m_maxSizeRollBackups = value; }
        }

        public string EnvironmentHandler
        {
            get { return m_environmentHandler; }
            set { m_environmentHandler = value; }
        }

        /// <summary>
        /// Gets or sets the maximum size that the output file is allowed to reach
        /// before being rolled over to backup files.
        /// </summary>
        /// <value>
        /// The maximum size in bytes that the output file is allowed to reach before being 
        /// rolled over to backup files.
        /// </value>
        /// <remarks>
        /// <para>
        /// This property is equivalent to <see cref="MaximumFileSize"/> except
        /// that it is required for differentiating the setter taking a
        /// <see cref="long"/> argument from the setter taking a <see cref="string"/> 
        /// argument.
        /// </para>
        /// <para>
        /// The default maximum file size is 10MB (10*1024*1024).
        /// </para>
        /// </remarks>
        public long MaxFileSize
        {
            get { return m_maxFileSize; }
            set { m_maxFileSize = value; }
        }

        /// <summary>
        /// Gets or sets the maximum size that the output file is allowed to reach
        /// before being rolled over to backup files.
        /// </summary>
        /// <value>
        /// The maximum size that the output file is allowed to reach before being 
        /// rolled over to backup files.
        /// </value>
        /// <remarks>
        /// <para>
        /// This property allows you to specify the maximum size with the
        /// suffixes "KB", "MB" or "GB" so that the size is interpreted being 
        /// expressed respectively in kilobytes, megabytes or gigabytes. 
        /// </para>
        /// <para>
        /// For example, the value "10KB" will be interpreted as 10240 bytes.
        /// </para>
        /// <para>
        /// The default maximum file size is 10MB.
        /// </para>
        /// <para>
        /// If you have the option to set the maximum file size programmatically
        /// consider using the <see cref="MaxFileSize"/> property instead as this
        /// allows you to set the size in bytes as a <see cref="Int64"/>.
        /// </para>
        /// </remarks>
        public string MaximumFileSize
        {
            get { return m_maxFileSize.ToString(NumberFormatInfo.InvariantInfo); }
            set { m_maxFileSize = OptionConverter.ToFileSize(value, m_maxFileSize + 1); }
        }

        /// <summary>
        /// Gets or sets the rolling file count direction. 
        /// </summary>
        /// <value>
        /// The rolling file count direction.
        /// </value>
        /// <remarks>
        /// <para>
        /// Indicates if the current file is the lowest numbered file or the
        /// highest numbered file.
        /// </para>
        /// <para>
        /// By default newer files have lower numbers (<see cref="CountDirection" /> &lt; 0),
        /// i.e. log.1 is most recent, log.5 is the 5th backup, etc...
        /// </para>
        /// <para>
        /// <see cref="CountDirection" /> &gt;= 0 does the opposite i.e.
        /// log.1 is the first backup made, log.5 is the 5th backup made, etc.
        /// For infinite backups use <see cref="CountDirection" /> &gt;= 0 to reduce 
        /// rollover costs.
        /// </para>
        /// <para>The default file count direction is -1.</para>
        /// </remarks>
        public int CountDirection
        {
            get { return m_countDirection; }
            set { m_countDirection = value; }
        }

        /// <summary>
        /// Gets or sets a value indicating whether to always log to
        /// the same file.
        /// </summary>
        /// <value>
        /// <c>true</c> if always should be logged to the same file, otherwise <c>false</c>.
        /// </value>
        /// <remarks>
        /// <para>
        /// By default file.log is always the current file.  Optionally
        /// file.log.yyyy-mm-dd for current formatted datePattern can by the currently
        /// logging file (or file.log.curSizeRollBackup or even
        /// file.log.yyyy-mm-dd.curSizeRollBackup).
        /// </para>
        /// <para>
        /// This will make time based rollovers with a large number of backups 
        /// much faster as the appender it won't have to rename all the backups!
        /// </para>
        /// </remarks>
        public bool StaticLogFileName
        {
            get { return m_staticLogFileName; }
            set { m_staticLogFileName = value; }
        }

        #endregion Public Instance Properties

        #region Override implementation of FileAppender

        /// <summary>
        /// Sets the quiet writer being used.
        /// </summary>
        /// <remarks>
        /// This method can be overridden by sub classes.
        /// </remarks>
        /// <param name="writer">the writer to set</param>
        override protected void SetQWForFiles(TextWriter writer)
        {
            QuietWriter = new CountingQuietTextWriter(writer, ErrorHandler);
        }

        /// <summary>
        /// Write out a logging event.
        /// </summary>
        /// <param name="loggingEvent">the event to write to file.</param>
        /// <remarks>
        /// <para>
        /// Handles append time behavior for RollingFileAppender.  This checks
        /// if a roll over either by date (checked first) or time (checked second)
        /// is need and then appends to the file last.
        /// </para>
        /// </remarks>
        override protected void Append(LoggingEvent loggingEvent)
        {
            AdjustFileBeforeAppend();
            base.Append(loggingEvent);
        }

        /// <summary>
        /// Write out an array of logging events.
        /// </summary>
        /// <param name="loggingEvents">the events to write to file.</param>
        /// <remarks>
        /// <para>
        /// Handles append time behavior for RollingFileAppender.  This checks
        /// if a roll over either by date (checked first) or time (checked second)
        /// is need and then appends to the file last.
        /// </para>
        /// </remarks>
        override protected void Append(LoggingEvent[] loggingEvents)
        {
            AdjustFileBeforeAppend();
            base.Append(loggingEvents);
        }

        /// <summary>
        /// Performs any required rolling before outputting the next event
        /// </summary>
        /// <remarks>
        /// <para>
        /// Handles append time behavior for RollingFileAppender.  This checks
        /// if a roll over either by date (checked first) or time (checked second)
        /// is need and then appends to the file last.
        /// </para>
        /// </remarks>
        virtual protected void AdjustFileBeforeAppend()
        {
            if (m_rollDate)
            {
                DateTime n = m_dateTime.Now;
                if (n >= m_nextCheck)
                {
                    m_now = n;
                    m_nextCheck = NextCheckDate(m_now, m_rollPoint);

                    RollOverTime(true);
                }
            }

            if (m_rollSize)
            {
                if ((File != null) && ((CountingQuietTextWriter)QuietWriter).Count >= m_maxFileSize)
                {
                    RollOverSize();
                }
            }
        }

        /// <summary>
        /// Creates and opens the file for logging.  If <see cref="StaticLogFileName"/>
        /// is false then the fully qualified name is determined and used.
        /// </summary>
        /// <param name="fileName">the name of the file to open</param>
        /// <param name="append">true to append to existing file</param>
        /// <remarks>
        /// <para>This method will ensure that the directory structure
        /// for the <paramref name="fileName"/> specified exists.</para>
        /// </remarks>
        override protected void OpenFile(string fileName, bool append)
        {
            lock (this)
            {
                if (fileName == null) fileName = File;
                fileName = GetNextOutputFileName(fileName);

                // Calculate the current size of the file
                long currentCount = 0;
                if (append)
                {
                    using (SecurityContext.Impersonate(this))
                    {
                        if (System.IO.File.Exists(fileName))
                        {
                            currentCount = (new FileInfo(fileName)).Length;
                        }
                    }
                }
                else
                {
                    if (LogLog.IsErrorEnabled)
                    {
                        // Internal check that the file is not being overwritten
                        // If not Appending to an existing file we should have rolled the file out of the
                        // way. Therefore we should not be over-writing an existing file.
                        // The only exception is if we are not allowed to roll the existing file away.
                        if (m_maxSizeRollBackups != 0 && FileExists(fileName))
                        {
                            //LogLog.Error("RollingFileAppender: INTERNAL ERROR. Append is False but OutputFile [" + fileName + "] already exists.");
                        }
                    }
                }

                if (!m_staticLogFileName)
                {
                    m_scheduledFilename = fileName;
                }

                try
                {
                    // Open the file (call the base class to do it)
                    base.OpenFile(fileName, append);

                    // Set the file size onto the counting writer
                    ((CountingQuietTextWriter)QuietWriter).Count = currentCount;
                }
                catch { }
            }
        }

        /// <summary>
        /// Get the current output file name
        /// </summary>
        /// <param name="fileName">the base file name</param>
        /// <returns>the output file name</returns>
        /// <remarks>
        /// The output file name is based on the base fileName specified.
        /// If <see cref="StaticLogFileName"/> is set then the output 
        /// file name is the same as the base file passed in. Otherwise
        /// the output file depends on the date pattern, on the count
        /// direction or both.
        /// </remarks>
        protected string GetNextOutputFileName(string fileName)
        {
            if (!m_staticLogFileName)
            {
                fileName = fileName.Trim();

                if (m_rollDate)
                {
                    fileName = FormatFileName(fileName, m_now);
                }

                if (m_countDirection >= 0)
                {
                    fileName = fileName + '.' + m_curSizeRollBackups;
                }
            }

            return fileName;
        }

        #endregion

        #region Initialize Options

        /// <summary>
        ///	Determines curSizeRollBackups (only within the current roll point)
        /// </summary>
        private void DetermineCurSizeRollBackups()
        {
            m_curSizeRollBackups = 0;

            string fullPath = null;
            string fileName = null;

            using (SecurityContext.Impersonate(this))
            {
                fullPath = System.IO.Path.GetFullPath(m_baseFileName);
                fileName = System.IO.Path.GetFileName(fullPath);
            }

            ArrayList arrayFiles = GetExistingFiles(fullPath);
            InitializeRollBackups(fileName, arrayFiles);

            //LogLog.Debug("RollingFileAppender: curSizeRollBackups starts at [" + m_curSizeRollBackups + "]");
        }

        /// <summary>
        /// Generates a wildcard pattern that can be used to find all files
        /// that are similar to the base file name.
        /// </summary>
        /// <param name="baseFileName"></param>
        /// <returns></returns>
        private static string GetWildcardPatternForFile(string baseFileName)
        {
            return baseFileName + '*';
        }

        /// <summary>
        /// Builds a list of filenames for all files matching the base filename plus a file
        /// pattern.
        /// </summary>
        /// <param name="baseFilePath"></param>
        /// <returns></returns>
        private ArrayList GetExistingFiles(string baseFilePath)
        {
            ArrayList alFiles = new ArrayList();

            string directory = null;

            using (SecurityContext.Impersonate(this))
            {
                string fullPath = Path.GetFullPath(baseFilePath);

                directory = Path.GetDirectoryName(fullPath);
                if (Directory.Exists(directory))
                {
                    string baseFileName = Path.GetFileName(fullPath);

                    string[] files = Directory.GetFiles(directory, GetWildcardPatternForFile(baseFileName));

                    if (files != null)
                    {
                        for (int i = 0; i < files.Length; i++)
                        {
                            string curFileName = Path.GetFileName(files[i]);
                            if (curFileName.StartsWith(baseFileName))
                            {
                                alFiles.Add(curFileName);
                            }
                        }
                    }
                }
            }
            //LogLog.Debug("RollingFileAppender: Searched for existing files in [" + directory + "]");
           
            return alFiles;
        }

        /// <summary>
        /// Initiates a roll over if needed for crossing a date boundary since the last run.
        /// </summary>
        private void RollOverIfDateBoundaryCrossing()
        {
            if (m_staticLogFileName && m_rollDate)
            {
                if (FileExists(m_baseFileName))
                {
                    DateTime last;
                    using (SecurityContext.Impersonate(this))
                    {
                        last = System.IO.File.GetLastWriteTime(m_baseFileName);
                    }
                    //LogLog.Debug("RollingFileAppender: [" + last.ToString(m_dateHourPattern, System.Globalization.DateTimeFormatInfo.InvariantInfo) + "] vs. [" + m_now.ToString(m_dateHourPattern, System.Globalization.DateTimeFormatInfo.InvariantInfo) + "]");

                    if (!(last.ToString(m_dateHourPattern, System.Globalization.DateTimeFormatInfo.InvariantInfo).Equals(m_now.ToString(m_dateHourPattern, System.Globalization.DateTimeFormatInfo.InvariantInfo))))
                    {
                        m_scheduledFilename = FormatFileName(m_baseFileName, last);
                        //LogLog.Debug("RollingFileAppender: Initial roll over to [" + m_scheduledFilename + "]");
                        RollOverTime(false);
                        //LogLog.Debug("RollingFileAppender: curSizeRollBackups after rollOver at [" + m_curSizeRollBackups + "]");
                    }
                }
            }
        }

        private string FormatFileName(string fileName, DateTime date)
        {
            string path = Path.Combine(date.ToString("yyyyMMdd"), DateTime.Now.Hour.ToString("D2"));
            string output = fileName.Replace("%DATA", path);
            return output;
        }

        /// <summary>
        /// Initializes based on existing conditions at time of <see cref="ActivateOptions"/>.
        /// </summary>
        /// <remarks>
        /// <para>
        /// Initializes based on existing conditions at time of <see cref="ActivateOptions"/>.
        /// The following is done
        /// <list type="bullet">
        ///	<item>determine curSizeRollBackups (only within the current roll point)</item>
        ///	<item>initiates a roll over if needed for crossing a date boundary since the last run.</item>
        ///	</list>
        ///	</para>
        /// </remarks>
        protected void ExistingInit()
        {
            DetermineCurSizeRollBackups();
            RollOverIfDateBoundaryCrossing();

            // If file exists and we are not appending then roll it out of the way
            if (AppendToFile == false)
            {
                bool fileExists = false;
                string fileName = GetNextOutputFileName(m_baseFileName);

                using (SecurityContext.Impersonate(this))
                {
                    fileExists = System.IO.File.Exists(fileName);
                }

                if (fileExists)
                {
                    if (m_maxSizeRollBackups == 0)
                    {
                        //LogLog.Debug("RollingFileAppender: Output file [" + fileName + "] already exists. MaxSizeRollBackups is 0; cannot roll. Overwriting existing file.");
                    }
                    else
                    {
                        //LogLog.Debug("RollingFileAppender: Output file [" + fileName + "] already exists. Not appending to file. Rolling existing file out of the way.");

                        RollOverRenameFiles(fileName);
                    }
                }
            }
        }

        /// <summary>
        /// Does the work of bumping the 'current' file counter higher
        /// to the highest count when an incremental file name is seen.
        /// The highest count is either the first file (when count direction
        /// is greater than 0) or the last file (when count direction less than 0).
        /// In either case, we want to know the highest count that is present.
        /// </summary>
        /// <param name="baseFile"></param>
        /// <param name="curFileName"></param>
        private void InitializeFromOneFile(string baseFile, string curFileName)
        {
            if (!curFileName.StartsWith(baseFile))
            {
                // This is not a log file, so ignore
                return;
            }
            if (curFileName.Equals(baseFile))
            {
                // Base log file is not an incremented logfile (.1 or .2, etc)
                return;
            }

            int index = curFileName.LastIndexOf(".");
            if (-1 == index)
            {
                // This is not an incremented logfile (.1 or .2)
                return;
            }

            if (m_staticLogFileName)
            {
                int endLength = curFileName.Length - index;
                if (baseFile.Length + endLength != curFileName.Length)
                {
                    // file is probably scheduledFilename + .x so I don't care
                    return;
                }
            }

            // Only look for files in the current roll point
            if (m_rollDate && !m_staticLogFileName)
            {
                if (!curFileName.StartsWith(FormatFileName(baseFile, m_dateTime.Now)))
                {
                    //LogLog.Debug("RollingFileAppender: Ignoring file [" + curFileName + "] because it is from a different date period");
                    return;
                }
            }

            try
            {
                // Bump the counter up to the highest count seen so far
                int backup;
                if (SystemInfo.TryParse(curFileName.Substring(index + 1), out backup))
                {
                    if (backup > m_curSizeRollBackups)
                    {
                        if (0 == m_maxSizeRollBackups)
                        {
                            // Stay at zero when zero backups are desired
                        }
                        else if (-1 == m_maxSizeRollBackups)
                        {
                            // Infinite backups, so go as high as the highest value
                            m_curSizeRollBackups = backup;
                        }
                        else
                        {
                            // Backups limited to a finite number
                            if (m_countDirection >= 0)
                            {
                                // Go with the highest file when counting up
                                m_curSizeRollBackups = backup;
                            }
                            else
                            {
                                // Clip to the limit when counting down
                                if (backup <= m_maxSizeRollBackups)
                                {
                                    m_curSizeRollBackups = backup;
                                }
                            }
                        }
                        //LogLog.Debug("RollingFileAppender: File name [" + curFileName + "] moves current count to [" + m_curSizeRollBackups + "]");
                    }
                }
            }
            catch (FormatException)
            {
                //this happens when file.log -> file.log.yyyy-mm-dd which is normal
                //when staticLogFileName == false
                //LogLog.Debug("RollingFileAppender: Encountered a backup file not ending in .x [" + curFileName + "]");
            }
        }

        /// <summary>
        /// Takes a list of files and a base file name, and looks for 
        /// 'incremented' versions of the base file.  Bumps the max
        /// count up to the highest count seen.
        /// </summary>
        /// <param name="baseFile"></param>
        /// <param name="arrayFiles"></param>
        private void InitializeRollBackups(string baseFile, ArrayList arrayFiles)
        {
            if (null != arrayFiles)
            {
                string baseFileLower = baseFile.ToLower(System.Globalization.CultureInfo.InvariantCulture);

                foreach (string curFileName in arrayFiles)
                {
                    InitializeFromOneFile(baseFileLower, curFileName.ToLower(System.Globalization.CultureInfo.InvariantCulture));
                }
            }
        }

        /// <summary>
        /// Calculates the RollPoint for the datePattern supplied.
        /// </summary>
        /// <param name="datePattern">the date pattern to calculate the check period for</param>
        /// <returns>The RollPoint that is most accurate for the date pattern supplied</returns>
        /// <remarks>
        /// Essentially the date pattern is examined to determine what the
        /// most suitable roll point is. The roll point chosen is the roll point
        /// with the smallest period that can be detected using the date pattern
        /// supplied. i.e. if the date pattern only outputs the year, month, day 
        /// and hour then the smallest roll point that can be detected would be
        /// and hourly roll point as minutes could not be detected.
        /// </remarks>
        private RollPoint ComputeCheckPeriod(string datePattern)
        {
            // s_date1970 is 1970-01-01 00:00:00 this is UniversalSortableDateTimePattern 
            // (based on ISO 8601) using universal time. This date is used for reference
            // purposes to calculate the resolution of the date pattern.

            // Get string representation of base line date
            string r0 = s_date1970.ToString(datePattern, System.Globalization.DateTimeFormatInfo.InvariantInfo);

            // Check each type of rolling mode starting with the smallest increment.
            for (int i = (int)RollPoint.TopOfMinute; i <= (int)RollPoint.TopOfMonth; i++)
            {
                // Get string representation of next pattern
                string r1 = NextCheckDate(s_date1970, (RollPoint)i).ToString(datePattern, System.Globalization.DateTimeFormatInfo.InvariantInfo);

                //LogLog.Debug("RollingFileAppender: Type = [" + i + "], r0 = [" + r0 + "], r1 = [" + r1 + "]");

                // Check if the string representations are different
                if (r0 != null && r1 != null && !r0.Equals(r1))
                {
                    // Found highest precision roll point
                    return (RollPoint)i;
                }
            }

            return RollPoint.InvalidRollPoint; // Deliberately head for trouble...
        }

        /// <summary>
        /// Initialize the appender based on the options set
        /// </summary>
        /// <remarks>
        /// <para>
        /// This is part of the <see cref="IOptionHandler"/> delayed object
        /// activation scheme. The <see cref="ActivateOptions"/> method must 
        /// be called on this object after the configuration properties have
        /// been set. Until <see cref="ActivateOptions"/> is called this
        /// object is in an undefined state and must not be used. 
        /// </para>
        /// <para>
        /// If any of the configuration properties are modified then 
        /// <see cref="ActivateOptions"/> must be called again.
        /// </para>
        /// <para>
        /// Sets initial conditions including date/time roll over information, first check,
        /// scheduledFilename, and calls <see cref="ExistingInit"/> to initialize
        /// the current number of backups.
        /// </para>
        /// </remarks>
        override public void ActivateOptions()
        {
            if (m_environmentHandler == null)
            {
                throw new ArgumentNullException("environmentHandler");
            }
            string[] split = m_environmentHandler.Split(new char[] { ',' });
            if (split.Length < 2) throw new Exception("Value has to be in format");

            Assembly ass = GetAssembly(split[1].Trim());
            if (ass == null)
            {
                throw new Exception("Assembly not found");
            }
            Type type = ass.GetType(split[0]);
            if (type == null)
            {
                throw new Exception("Type not found");
            }
            else
            {
                _handlerInstance = (ILogEnvironmentHandler)Activator.CreateInstance(type);
            }
            if (m_rollDate && m_dateHourPattern != null)
            {
                m_now = m_dateTime.Now;
                m_rollPoint = ComputeCheckPeriod(m_dateHourPattern);

                if (m_rollPoint == RollPoint.InvalidRollPoint)
                {
                    throw new ArgumentException("Invalid RollPoint, unable to parse [" + m_dateHourPattern + "]");
                }

                // next line added as this removes the name check in rollOver
                m_nextCheck = NextCheckDate(m_now, m_rollPoint);
            }
            else
            {
                if (m_rollDate)
                {
                    ErrorHandler.Error("Either DatePattern or rollingStyle options are not set for [" + Name + "].");
                }
            }

            if (SecurityContext == null)
            {
                SecurityContext = SecurityContextProvider.DefaultProvider.CreateSecurityContext(this);
            }

            using (SecurityContext.Impersonate(this))
            {
                // Store fully qualified base file name
                m_baseFileName = File;
            }

            if (m_rollDate && File != null && m_scheduledFilename == null)
            {
                m_scheduledFilename = FormatFileName(File, m_now);
            }

            ExistingInit();
            //base.ActivateOptions();
        }

        private Assembly GetAssembly(string assemblyName)
        {
            Assembly[] assemblyList = AppDomain.CurrentDomain.GetAssemblies();
            foreach (Assembly temp in assemblyList)
            {
                AssemblyName tempName = temp.GetName();
                if (tempName.Name.Equals(assemblyName)) return temp;
            }
            return null;
        }

        #endregion

        #region Roll File

        /// <summary>
        /// Rollover the file(s) to date/time tagged file(s).
        /// </summary>
        /// <param name="fileIsOpen">set to true if the file to be rolled is currently open</param>
        /// <remarks>
        /// <para>
        /// Rollover the file(s) to date/time tagged file(s).
        /// Resets curSizeRollBackups. 
        /// If fileIsOpen is set then the new file is opened (through SafeOpenFile).
        /// </para>
        /// </remarks>
        protected void RollOverTime(bool fileIsOpen)
        {
            if (m_staticLogFileName)
            {
                // Compute filename, but only if datePattern is specified
                if (m_dateHourPattern == null)
                {
                    ErrorHandler.Error("Missing DatePattern option in rollOver().");
                    return;
                }

                //is the new file name equivalent to the 'current' one
                //something has gone wrong if we hit this -- we should only
                //roll over if the new file will be different from the old
                if (m_scheduledFilename.Equals(FormatFileName(File, m_now)))
                {
                    ErrorHandler.Error("Compare " + m_scheduledFilename + " : " + FormatFileName(File, m_now));
                    return;
                }

                if (fileIsOpen)
                {
                    // close current file, and rename it to datedFilename
                    this.CloseFile();
                }

                //we may have to roll over a large number of backups here
                for (int i = 1; i <= m_curSizeRollBackups; i++)
                {
                    string from = File + '.' + i;
                    string to = m_scheduledFilename + '.' + i;
                    RollFile(from, to);
                }

                RollFile(File, m_scheduledFilename);
            }

            //We've cleared out the old date and are ready for the new
            m_curSizeRollBackups = 0;

            //new scheduled name
            m_scheduledFilename = FormatFileName(File, m_now);

            if (fileIsOpen)
            {
                // This will also close the file. This is OK since multiple close operations are safe.
                SafeOpenFile(m_baseFileName, false);
            }
        }

        /// <summary>
        /// Renames file <paramref name="fromFile"/> to file <paramref name="toFile"/>.
        /// </summary>
        /// <param name="fromFile">Name of existing file to roll.</param>
        /// <param name="toFile">New name for file.</param>
        /// <remarks>
        /// <para>
        /// Renames file <paramref name="fromFile"/> to file <paramref name="toFile"/>. It
        /// also checks for existence of target file and deletes if it does.
        /// </para>
        /// </remarks>
        protected void RollFile(string fromFile, string toFile)
        {
            if (FileExists(fromFile))
            {
                // Delete the toFile if it exists
                DeleteFile(toFile);

                // We may not have permission to move the file, or the file may be locked
                try
                {
                    //LogLog.Debug("RollingFileAppender: Moving [" + fromFile + "] -> [" + toFile + "]");
                    using (SecurityContext.Impersonate(this))
                    {
                        System.IO.File.Move(fromFile, toFile);
                    }
                }
                catch (Exception moveEx)
                {
                    ErrorHandler.Error("Exception while rolling file [" + fromFile + "] -> [" + toFile + "]", moveEx, ErrorCode.GenericFailure);
                }
            }
            else
            {
                //LogLog.Warn("RollingFileAppender: Cannot RollFile [" + fromFile + "] -> [" + toFile + "]. Source does not exist");
            }
        }

        /// <summary>
        /// Test if a file exists at a specified path
        /// </summary>
        /// <param name="path">the path to the file</param>
        /// <returns>true if the file exists</returns>
        /// <remarks>
        /// <para>
        /// Test if a file exists at a specified path
        /// </para>
        /// </remarks>
        protected bool FileExists(string path)
        {
            using (SecurityContext.Impersonate(this))
            {
                return System.IO.File.Exists(path);
            }
        }

        /// <summary>
        /// Deletes the specified file if it exists.
        /// </summary>
        /// <param name="fileName">The file to delete.</param>
        /// <remarks>
        /// <para>
        /// Delete a file if is exists.
        /// The file is first moved to a new filename then deleted.
        /// This allows the file to be removed even when it cannot
        /// be deleted, but it still can be moved.
        /// </para>
        /// </remarks>
        protected void DeleteFile(string fileName)
        {
            if (FileExists(fileName))
            {
                // We may not have permission to delete the file, or the file may be locked

                string fileToDelete = fileName;

                // Try to move the file to temp name.
                // If the file is locked we may still be able to move it
                string tempFileName = fileName + "." + Environment.TickCount + ".DeletePending";
                try
                {
                    using (SecurityContext.Impersonate(this))
                    {
                        System.IO.File.Move(fileName, tempFileName);
                    }
                    fileToDelete = tempFileName;
                }
                catch (Exception moveEx)
                {
                    //LogLog.Debug("RollingFileAppender: Exception while moving file to be deleted [" + fileName + "] -> [" + tempFileName + "]", moveEx);
                }

                // Try to delete the file (either the original or the moved file)
                try
                {
                    using (SecurityContext.Impersonate(this))
                    {
                        System.IO.File.Delete(fileToDelete);
                    }
                    //LogLog.Debug("RollingFileAppender: Deleted file [" + fileName + "]");
                }
                catch (Exception deleteEx)
                {
                    if (fileToDelete == fileName)
                    {
                        // Unable to move or delete the file
                        ErrorHandler.Error("Exception while deleting file [" + fileToDelete + "]", deleteEx, ErrorCode.GenericFailure);
                    }
                    else
                    {
                        // Moved the file, but the delete failed. File is probably locked.
                        // The file should automatically be deleted when the lock is released.
                        //LogLog.Debug("RollingFileAppender: Exception while deleting temp file [" + fileToDelete + "]", deleteEx);
                    }
                }
            }
        }

        /// <summary>
        /// Implements file roll base on file size.
        /// </summary>
        /// <remarks>
        /// <para>
        /// If the maximum number of size based backups is reached
        /// (<c>curSizeRollBackups == maxSizeRollBackups</c>) then the oldest
        /// file is deleted -- its index determined by the sign of countDirection.
        /// If <c>countDirection</c> &lt; 0, then files
        /// {<c>File.1</c>, ..., <c>File.curSizeRollBackups -1</c>}
        /// are renamed to {<c>File.2</c>, ...,
        /// <c>File.curSizeRollBackups</c>}. Moreover, <c>File</c> is
        /// renamed <c>File.1</c> and closed.
        /// </para>
        /// <para>
        /// A new file is created to receive further log output.
        /// </para>
        /// <para>
        /// If <c>maxSizeRollBackups</c> is equal to zero, then the
        /// <c>File</c> is truncated with no backup files created.
        /// </para>
        /// <para>
        /// If <c>maxSizeRollBackups</c> &lt; 0, then <c>File</c> is
        /// renamed if needed and no files are deleted.
        /// </para>
        /// </remarks>
        protected void RollOverSize()
        {
            this.CloseFile(); // keep windows happy.

            //LogLog.Debug("RollingFileAppender: rolling over count [" + ((CountingQuietTextWriter)QuietWriter).Count + "]");
            //LogLog.Debug("RollingFileAppender: maxSizeRollBackups [" + m_maxSizeRollBackups + "]");
            //LogLog.Debug("RollingFileAppender: curSizeRollBackups [" + m_curSizeRollBackups + "]");
            //LogLog.Debug("RollingFileAppender: countDirection [" + m_countDirection + "]");

            RollOverRenameFiles(File);

            if (!m_staticLogFileName && m_countDirection >= 0)
            {
                m_curSizeRollBackups++;
            }

            // This will also close the file. This is OK since multiple close operations are safe.
            SafeOpenFile(m_baseFileName, false);
        }

        /// <summary>
        /// Implements file roll.
        /// </summary>
        /// <param name="baseFileName">the base name to rename</param>
        /// <remarks>
        /// <para>
        /// If the maximum number of size based backups is reached
        /// (<c>curSizeRollBackups == maxSizeRollBackups</c>) then the oldest
        /// file is deleted -- its index determined by the sign of countDirection.
        /// If <c>countDirection</c> &lt; 0, then files
        /// {<c>File.1</c>, ..., <c>File.curSizeRollBackups -1</c>}
        /// are renamed to {<c>File.2</c>, ...,
        /// <c>File.curSizeRollBackups</c>}. 
        /// </para>
        /// <para>
        /// If <c>maxSizeRollBackups</c> is equal to zero, then the
        /// <c>File</c> is truncated with no backup files created.
        /// </para>
        /// <para>
        /// If <c>maxSizeRollBackups</c> &lt; 0, then <c>File</c> is
        /// renamed if needed and no files are deleted.
        /// </para>
        /// <para>
        /// This is called by <see cref="RollOverSize"/> to rename the files.
        /// </para>
        /// </remarks>
        protected void RollOverRenameFiles(string baseFileName)
        {
            // If maxBackups <= 0, then there is no file renaming to be done.
            if (m_maxSizeRollBackups != 0)
            {
                if (m_countDirection < 0)
                {
                    // Delete the oldest file, to keep Windows happy.
                    if (m_curSizeRollBackups == m_maxSizeRollBackups)
                    {
                        DeleteFile(baseFileName + '.' + m_maxSizeRollBackups);
                        m_curSizeRollBackups--;
                    }

                    // Map {(maxBackupIndex - 1), ..., 2, 1} to {maxBackupIndex, ..., 3, 2}
                    for (int i = m_curSizeRollBackups; i >= 1; i--)
                    {
                        RollFile((baseFileName + "." + i), (baseFileName + '.' + (i + 1)));
                    }

                    m_curSizeRollBackups++;

                    // Rename fileName to fileName.1
                    RollFile(baseFileName, baseFileName + ".1");
                }
                else
                {
                    //countDirection >= 0
                    if (m_curSizeRollBackups >= m_maxSizeRollBackups && m_maxSizeRollBackups > 0)
                    {
                        //delete the first and keep counting up.
                        int oldestFileIndex = m_curSizeRollBackups - m_maxSizeRollBackups;

                        // If static then there is 1 file without a number, therefore 1 less archive
                        if (m_staticLogFileName)
                        {
                            oldestFileIndex++;
                        }

                        // If using a static log file then the base for the numbered sequence is the baseFileName passed in
                        // If not using a static log file then the baseFileName will already have a numbered postfix which
                        // we must remove, however it may have a date postfix which we must keep!
                        string archiveFileBaseName = baseFileName;
                        if (!m_staticLogFileName)
                        {
                            int lastDotIndex = archiveFileBaseName.LastIndexOf(".");
                            if (lastDotIndex >= 0)
                            {
                                archiveFileBaseName = archiveFileBaseName.Substring(0, lastDotIndex);
                            }
                        }

                        // Delete the archive file
                        DeleteFile(archiveFileBaseName + '.' + oldestFileIndex);
                    }

                    if (m_staticLogFileName)
                    {
                        m_curSizeRollBackups++;
                        RollFile(baseFileName, baseFileName + '.' + m_curSizeRollBackups);
                    }
                }
            }
        }

        #endregion

        #region NextCheckDate

        /// <summary>
        /// Get the start time of the next window for the current rollpoint
        /// </summary>
        /// <param name="currentDateTime">the current date</param>
        /// <param name="rollPoint">the type of roll point we are working with</param>
        /// <returns>the start time for the next roll point an interval after the currentDateTime date</returns>
        /// <remarks>
        /// <para>
        /// Returns the date of the next roll point after the currentDateTime date passed to the method.
        /// </para>
        /// <para>
        /// The basic strategy is to subtract the time parts that are less significant
        /// than the rollpoint from the current time. This should roll the time back to
        /// the start of the time window for the current rollpoint. Then we add 1 window
        /// worth of time and get the start time of the next window for the rollpoint.
        /// </para>
        /// </remarks>
        protected DateTime NextCheckDate(DateTime currentDateTime, RollPoint rollPoint)
        {
            // Local variable to work on (this does not look very efficient)
            DateTime current = currentDateTime;

            // Do slightly different things depending on what the type of roll point we want.
            switch (rollPoint)
            {
                case RollPoint.TopOfMinute:
                    current = current.AddMilliseconds(-current.Millisecond);
                    current = current.AddSeconds(-current.Second);
                    current = current.AddMinutes(1);
                    break;

                case RollPoint.TopOfHour:
                    current = current.AddMilliseconds(-current.Millisecond);
                    current = current.AddSeconds(-current.Second);
                    current = current.AddMinutes(-current.Minute);
                    current = current.AddHours(1);
                    break;

                case RollPoint.HalfDay:
                    current = current.AddMilliseconds(-current.Millisecond);
                    current = current.AddSeconds(-current.Second);
                    current = current.AddMinutes(-current.Minute);

                    if (current.Hour < 12)
                    {
                        current = current.AddHours(12 - current.Hour);
                    }
                    else
                    {
                        current = current.AddHours(-current.Hour);
                        current = current.AddDays(1);
                    }
                    break;

                case RollPoint.TopOfDay:
                    current = current.AddMilliseconds(-current.Millisecond);
                    current = current.AddSeconds(-current.Second);
                    current = current.AddMinutes(-current.Minute);
                    current = current.AddHours(-current.Hour);
                    current = current.AddDays(1);
                    break;

                case RollPoint.TopOfWeek:
                    current = current.AddMilliseconds(-current.Millisecond);
                    current = current.AddSeconds(-current.Second);
                    current = current.AddMinutes(-current.Minute);
                    current = current.AddHours(-current.Hour);
                    current = current.AddDays(7 - (int)current.DayOfWeek);
                    break;

                case RollPoint.TopOfMonth:
                    current = current.AddMilliseconds(-current.Millisecond);
                    current = current.AddSeconds(-current.Second);
                    current = current.AddMinutes(-current.Minute);
                    current = current.AddHours(-current.Hour);
                    current = current.AddDays(1 - current.Day); /* first day of month is 1 not 0 */
                    current = current.AddMonths(1);
                    break;
            }
            return current;
        }

        #endregion

        #region Private Instance Fields

        /// <summary>
        /// This object supplies the current date/time.  Allows test code to plug in
        /// a method to control this class when testing date/time based rolling.
        /// </summary>
        private IDateTime m_dateTime = null;

        /// <summary>
        /// The actual formatted filename that is currently being written to
        /// or will be the file transferred to on roll over
        /// (based on staticLogFileName).
        /// </summary>
        private string m_scheduledFilename = null;

        /// <summary>
        /// The timestamp when we shall next recompute the filename.
        /// </summary>
        private DateTime m_nextCheck = DateTime.MaxValue;

        /// <summary>
        /// Holds date of last roll over
        /// </summary>
        private DateTime m_now;

        /// <summary>
        /// The type of rolling done
        /// </summary>
        private RollPoint m_rollPoint;

        /// <summary>
        /// The default maximum file size is 10MB
        /// </summary>
        private long m_maxFileSize = 10 * 1024 * 1024;

        /// <summary>
        /// There is zero backup files by default
        /// </summary>
        private int m_maxSizeRollBackups = 0;

        /// <summary>
        /// How many sized based backups have been made so far
        /// </summary>
        private int m_curSizeRollBackups = 0;

        /// <summary>
        /// The rolling file count direction. 
        /// </summary>
        private int m_countDirection = -1;

        /// <summary>
        /// Cache flag set if we are rolling by date.
        /// </summary>
        private bool m_rollDate = true;

        /// <summary>
        /// Cache flag set if we are rolling by size.
        /// </summary>
        private bool m_rollSize = true;

        /// <summary>
        /// Value indicating whether to always log to the same file.
        /// </summary>
        private bool m_staticLogFileName = false;

        /// <summary>
        /// FileName provided in configuration.  Used for rolling properly
        /// </summary>
        private string m_baseFileName;

        private string m_dateHourPattern = "yyyyMMddHH";

        private string m_environmentHandler;

        private ILogEnvironmentHandler _handlerInstance;

        #endregion Private Instance Fields

        #region Static Members

        /// <summary>
        /// The 1st of January 1970 in UTC
        /// </summary>
        private static readonly DateTime s_date1970 = new DateTime(1970, 1, 1);

        #endregion

        #region DateTime

        /// <summary>
        /// This interface is used to supply Date/Time information to the <see cref="RollingFileAppender"/>.
        /// </summary>
        /// <remarks>
        /// This interface is used to supply Date/Time information to the <see cref="RollingFileAppender"/>.
        /// Used primarily to allow test classes to plug themselves in so they can
        /// supply test date/times.
        /// </remarks>
        public interface IDateTime
        {
            /// <summary>
            /// Gets the <i>current</i> time.
            /// </summary>
            /// <value>The <i>current</i> time.</value>
            /// <remarks>
            /// <para>
            /// Gets the <i>current</i> time.
            /// </para>
            /// </remarks>
            DateTime Now { get; }
        }

        /// <summary>
        /// Default implementation of <see cref="IDateTime"/> that returns the current time.
        /// </summary>
        private class DefaultDateTime : IDateTime
        {
            /// <summary>
            /// Gets the <b>current</b> time.
            /// </summary>
            /// <value>The <b>current</b> time.</value>
            /// <remarks>
            /// <para>
            /// Gets the <b>current</b> time.
            /// </para>
            /// </remarks>
            public DateTime Now
            {
                get { return DateTime.Now; }
            }
        }

        #endregion DateTime
    }
}
