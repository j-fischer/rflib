/*
 * Copyright (c) 2019 Johannes Fischer <fischer.jh@gmail.com>
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of mosquitto nor the names of its
 *    contributors may be used to endorse or promote products derived from
 *    this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * @group Logger
 * @description Log Levels used to determine the behavior of the jfflib_Logger implementation. 
 *              Valid levels are NONE, TRACE, DEBUG, INFO, WARN, ERROR, and FATAL.
 */ 
@SuppressWarnings('PMD.ClassNamingConventions')
public without sharing class rflib_LogLevel {
  
  public static final rflib_LogLevel TRACE = new rflib_LogLevel(LoggingLevel.FINE, 0, 'TRACE');
  public static final rflib_LogLevel DEBUG = new rflib_LogLevel(LoggingLevel.DEBUG, 1, 'DEBUG');
  public static final rflib_LogLevel INFO = new rflib_LogLevel(LoggingLevel.INFO, 2, 'INFO');
  public static final rflib_LogLevel WARN = new rflib_LogLevel(LoggingLevel.WARN, 3, 'WARN');
  public static final rflib_LogLevel ERROR = new rflib_LogLevel(LoggingLevel.ERROR, 4, 'ERROR');
  public static final rflib_LogLevel FATAL = new rflib_LogLevel(LoggingLevel.ERROR, 5, 'FATAL');
  public static final rflib_LogLevel NONE = new rflib_LogLevel(LoggingLevel.NONE, 100, 'NONE');

  /**
   * Create a instance of the rflib_LogLevel enum from a string.
   * 
   * @param  level Case incensitive string of the logging level.
   * @return       Instance of the rflib_LogLevel enum.
   */
  @SuppressWarnings('PMD.EmptyStatementBlock')
  public static rflib_LogLevel fromString(String level) {
    switch on level.toUpperCase() {
      when 'TRACE' {
        return rflib_LogLevel.TRACE;
      }

      when 'DEBUG' {
        return rflib_LogLevel.DEBUG;
      }

      when 'INFO' {
        return rflib_LogLevel.INFO;
      }

      when 'WARN' {
        return rflib_LogLevel.WARN;
      }

      when 'ERROR' {
        return rflib_LogLevel.ERROR;
      }

      when 'FATAL' {
        return rflib_LogLevel.FATAL;
      }

      when else {
        return rflib_LogLevel.NONE;
      }
    }
  }

  private final LoggingLevel systemLoggingLevel;
  private final Integer level;
  private final String name;

  private rflib_LogLevel(LoggingLevel systemLoggingLevel, Integer level, String name) {
    this.systemLoggingLevel = systemLoggingLevel;
    this.level = level;
    this.name = name;
  }

  /**
   * Retuns the Apex System logging level that this enum instance represents.
   * @return   return description
   */
  public LoggingLevel getLoggingLevel() {
    return systemLoggingLevel;
  }

  /**
   * Evaluates if the given log level is encompassed by the current log level.
   *  
   * @param  otherLevel The other log level to compare the current level to. 
   * @return            For example, if the current
   *                    If the current log level is INFO and the provided log level is WARN, the function will return true. 
   *                    If the current log level is INFO and the provided log level is INFO, the function will return true. 
   *                    If the current log level is INFO and the provided log level is DEBUG, the function will return false. 
   */
  public Boolean encompasses(rflib_LogLevel otherLevel) {
    if (level == rflib_LogLevel.NONE.level || otherLevel.level == rflib_LogLevel.NONE.level) {
      return false;
    }
    return level <= otherLevel.level;
  } 

  /**
  * Returns the log level as a String. 
  * 
  * @return   String represenation in uppercase.
  */
  public override String toString() {
    return name;
  }
}
