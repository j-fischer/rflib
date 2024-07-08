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
public class rflib_MockQueryExecutor implements rflib_QueryExecutor {
    
    private final Integer countResult;
    private final List<SObject> queryResult;

    public rflib_MockQueryExecutor(Integer countResult, List<SObject> queryResult) {
        this.countResult = countResult;
        this.queryResult = queryResult;
    }

    public Integer countQuery(String query) {
        return countResult;
    }

    public List<SObject> query(String query) {
        return queryResult;
    }

    public rflib_DatabaseCursorQueryResult fetch(String query, Integer position, Integer count) {
        if (position < 0 || position >= queryResult.size()) {
            return new rflib_DatabaseCursorQueryResult(new List<SObject>(), position, queryResult.size());
        }

        Integer endIndex = Math.min(position + count, queryResult.size());

        List<SObject> result = new List<SObject>();
        for (Object o : rflib_CollectionUtil.sublist(queryResult, position, endIndex)) {
            result.add((SObject) o);
        }

        return new rflib_DatabaseCursorQueryResult(result, position, queryResult.size());
    }
}
