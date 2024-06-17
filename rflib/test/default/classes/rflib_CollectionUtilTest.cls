/*
 * Copyright (c) 2024 Johannes Fischer <fischer.jh@gmail.com>
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
 * 3. Neither the name "RFLIB", the name of the copyright holder, nor the names of its
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
@IsTest
@SuppressWarnings('PMD.ClassNamingConventions')
private class rflib_CollectionUtilTest {
    
    @IsTest
    private static void testSublistNormalRange() {
        List<Object> input = new List<Object>{'A', 'B', 'C', 'D', 'E'};
        Integer startIndex = 1;
        Integer count = 3;

        List<Object> result = rflib_CollectionUtil.sublist(input, startIndex, count);

        System.assertEquals(new List<Object>{'B', 'C', 'D'}, result);
    }

    @IsTest
    private static void testSublistEdgeCaseStart() {
        List<Object> input = new List<Object>{'A', 'B', 'C', 'D', 'E'};
        Integer startIndex = 4;
        Integer count = 2;

        List<Object> result = rflib_CollectionUtil.sublist(input, startIndex, count);

        System.assertEquals(new List<Object>{'E'}, result);
    }

    @IsTest
    private static void testSublistExceedCount() {
        List<Object> input = new List<Object>{'A', 'B', 'C', 'D', 'E'};
        Integer startIndex = 2;
        Integer count = 10;

        List<Object> result = rflib_CollectionUtil.sublist(input, startIndex, count);

        System.assertEquals(new List<Object>{'C', 'D', 'E'}, result);
    }

    @IsTest
    private static void testSublistEmptyList() {
        List<Object> input = new List<Object>{};
        Integer startIndex = 0;
        Integer count = 2;

        List<Object> result = rflib_CollectionUtil.sublist(input, startIndex, count);

        System.assertEquals(new List<Object>{}, result);
    }

    @IsTest
    private static void testSublistZeroCount() {
        List<Object> input = new List<Object>{'A', 'B', 'C'};
        Integer startIndex = 1;
        Integer count = 0;

        List<Object> result = rflib_CollectionUtil.sublist(input, startIndex, count);

        System.assertEquals(new List<Object>{}, result);
    }

    @IsTest
    private static void testSublistNegativeStartIndex() {
        List<Object> input = new List<Object>{'A', 'B', 'C', 'D', 'E'};
        Integer startIndex = -1;
        Integer count = 2;

        Test.startTest();
        try {
            List<Object> result = rflib_CollectionUtil.sublist(input, startIndex, count);
            System.assert(false, 'Exception should have been thrown for negative startIndex');
        } catch (Exception e) {
            System.assert(true, 'Expected exception for negative startIndex');
        }
        Test.stopTest();
    }

    @IsTest
    private static void testSublistStartIndexOutOfBounds() {
        List<Object> input = new List<Object>{'A', 'B', 'C', 'D', 'E'};
        Integer startIndex = 10;
        Integer count = 2;

        List<Object> result = rflib_CollectionUtil.sublist(input, startIndex, count);

        System.assertEquals(new List<Object>{}, result);
    }
}
