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
@isTest
@SuppressWarnings('PMD.ClassNamingConventions')
private class rflib_LogLevelTest {
    
  @isTest
  public static void testNone() {
    rflib_LogLevel level = rflib_LogLevel.NONE;

    System.assertEquals(LoggingLevel.NONE, level.getLoggingLevel());
    System.assertEquals('NONE', level.toString());
    System.assertEquals(false, level.encompasses(rflib_LogLevel.TRACE));
    System.assertEquals(false, level.encompasses(rflib_LogLevel.DEBUG));
    System.assertEquals(false, level.encompasses(rflib_LogLevel.INFO));
    System.assertEquals(false, level.encompasses(rflib_LogLevel.WARN));
    System.assertEquals(false, level.encompasses(rflib_LogLevel.ERROR));
    System.assertEquals(false, level.encompasses(rflib_LogLevel.FATAL));
    System.assertEquals(false, level.encompasses(rflib_LogLevel.NONE));
  }   
  
  @isTest
  public static void testTrace() {
    rflib_LogLevel level = rflib_LogLevel.TRACE;

    System.assertEquals(LoggingLevel.FINE, level.getLoggingLevel());
    System.assertEquals('TRACE', level.toString());
    System.assertEquals(true, level.encompasses(rflib_LogLevel.TRACE));
    System.assertEquals(true, level.encompasses(rflib_LogLevel.DEBUG));
    System.assertEquals(true, level.encompasses(rflib_LogLevel.INFO));
    System.assertEquals(true, level.encompasses(rflib_LogLevel.WARN));
    System.assertEquals(true, level.encompasses(rflib_LogLevel.ERROR));
    System.assertEquals(true, level.encompasses(rflib_LogLevel.FATAL));
    System.assertEquals(false, level.encompasses(rflib_LogLevel.NONE));
  }

  @isTest
  public static void testDebug() {
    rflib_LogLevel level = rflib_LogLevel.DEBUG;

    System.assertEquals(LoggingLevel.DEBUG, level.getLoggingLevel());
    System.assertEquals('DEBUG', level.toString());
    System.assertEquals(false, level.encompasses(rflib_LogLevel.TRACE));
    System.assertEquals(true, level.encompasses(rflib_LogLevel.DEBUG));
    System.assertEquals(true, level.encompasses(rflib_LogLevel.INFO));
    System.assertEquals(true, level.encompasses(rflib_LogLevel.WARN));
    System.assertEquals(true, level.encompasses(rflib_LogLevel.ERROR));
    System.assertEquals(true, level.encompasses(rflib_LogLevel.FATAL));
    System.assertEquals(false, level.encompasses(rflib_LogLevel.NONE));
  }

  @isTest
  public static void testInfo() {
    rflib_LogLevel level = rflib_LogLevel.INFO;

    System.assertEquals(LoggingLevel.INFO, level.getLoggingLevel());
    System.assertEquals('INFO', level.toString());
    System.assertEquals(false, level.encompasses(rflib_LogLevel.TRACE));
    System.assertEquals(false, level.encompasses(rflib_LogLevel.DEBUG));
    System.assertEquals(true, level.encompasses(rflib_LogLevel.INFO));
    System.assertEquals(true, level.encompasses(rflib_LogLevel.WARN));
    System.assertEquals(true, level.encompasses(rflib_LogLevel.ERROR));
    System.assertEquals(true, level.encompasses(rflib_LogLevel.FATAL));
    System.assertEquals(false, level.encompasses(rflib_LogLevel.NONE));
  }

  @isTest
  public static void testWarn() {
    rflib_LogLevel level = rflib_LogLevel.WARN;

    System.assertEquals(LoggingLevel.WARN, level.getLoggingLevel());
    System.assertEquals('WARN', level.toString());
    System.assertEquals(false, level.encompasses(rflib_LogLevel.TRACE));
    System.assertEquals(false, level.encompasses(rflib_LogLevel.DEBUG));
    System.assertEquals(false, level.encompasses(rflib_LogLevel.INFO));
    System.assertEquals(true, level.encompasses(rflib_LogLevel.WARN));
    System.assertEquals(true, level.encompasses(rflib_LogLevel.ERROR));
    System.assertEquals(true, level.encompasses(rflib_LogLevel.FATAL));
    System.assertEquals(false, level.encompasses(rflib_LogLevel.NONE));
  }

  @isTest
  public static void testError() {
    rflib_LogLevel level = rflib_LogLevel.ERROR;

    System.assertEquals(LoggingLevel.ERROR, level.getLoggingLevel());
    System.assertEquals('ERROR', level.toString());
    System.assertEquals(false, level.encompasses(rflib_LogLevel.TRACE));
    System.assertEquals(false, level.encompasses(rflib_LogLevel.DEBUG));
    System.assertEquals(false, level.encompasses(rflib_LogLevel.INFO));
    System.assertEquals(false, level.encompasses(rflib_LogLevel.WARN));
    System.assertEquals(true, level.encompasses(rflib_LogLevel.ERROR));
    System.assertEquals(true, level.encompasses(rflib_LogLevel.FATAL));
    System.assertEquals(false, level.encompasses(rflib_LogLevel.NONE));
  }

  @isTest
  public static void testFatal() {
    rflib_LogLevel level = rflib_LogLevel.FATAL;

    System.assertEquals(LoggingLevel.ERROR, level.getLoggingLevel());
    System.assertEquals('FATAL', level.toString());
    System.assertEquals(false, level.encompasses(rflib_LogLevel.TRACE));
    System.assertEquals(false, level.encompasses(rflib_LogLevel.DEBUG));
    System.assertEquals(false, level.encompasses(rflib_LogLevel.INFO));
    System.assertEquals(false, level.encompasses(rflib_LogLevel.WARN));
    System.assertEquals(false, level.encompasses(rflib_LogLevel.ERROR));
    System.assertEquals(true, level.encompasses(rflib_LogLevel.FATAL));
    System.assertEquals(false, level.encompasses(rflib_LogLevel.NONE));
  }

  @isTest
  public static void testFromString() {
    System.assertEquals(rflib_LogLevel.TRACE, rflib_LogLevel.fromString('trace'));
    System.assertEquals(rflib_LogLevel.DEBUG, rflib_LogLevel.fromString('debug'));
    System.assertEquals(rflib_LogLevel.INFO, rflib_LogLevel.fromString('info'));
    System.assertEquals(rflib_LogLevel.WARN, rflib_LogLevel.fromString('warn'));
    System.assertEquals(rflib_LogLevel.ERROR, rflib_LogLevel.fromString('error'));
    System.assertEquals(rflib_LogLevel.FATAL, rflib_LogLevel.fromString('fatal'));
    System.assertEquals(rflib_LogLevel.NONE, rflib_LogLevel.fromString('none'));
    System.assertEquals(rflib_LogLevel.NONE, rflib_LogLevel.fromString('foo'));
  }
}
