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

  /**
  * @group Logger
  * @description The `rflib_QueryExecutor` reference implementation acting as a proxy to Salesforce's `Database` class.
  */
@SuppressWarnings('PMD.ClassNamingConventions')
public inherited sharing class rflib_DatabaseQueryExecutor implements rflib_QueryExecutor {
    
    public Integer countQuery(String query) {
        return Database.countQuery(query);
    }

    public List<SObject> query(String query) {
        return Database.query(query);
    }

    public rflib_DatabaseCursorQueryResult fetch(String query, Integer position, Integer count) {
        Database.Cursor cursor = Database.getCursor(query);
        Integer numTotalRecords = cursor.getNumRecords();
        
        List<SObject> result = cursor.fetch(position, Math.min(count, numTotalRecords - position));

        return new rflib_DatabaseCursorQueryResult(
            result,
            position,
            numTotalRecords
        );
    }
}
