/*
 * Copyright (c) 2025 Johannes Fischer <fischer.jh@gmail.com>
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
 * @description Parses the Platform_Info__c JSON of an rflib_Log_Event__e into a flat map of
 *              namespaced, typed telemetry attributes so log destinations (OpenTelemetry,
 *              Application Insights) can index and filter on individual values.
 *
 *              Two source shapes are produced by RFLIB:
 *              - Apex (rflib_DefaultLogger): a flat map of governor limits, e.g.
 *                {"CPU Time":123,"SOQL queries":5,"Heap Size":4096}. Emitted under rflib.apex.*.
 *              - Browser (rflibLogger LWC): performance.toJSON() (nested timeOrigin/timing/
 *                navigation) plus an injected userAgent. The user agent is emitted as the OTel
 *                semantic attribute user_agent.original; the remainder under rflib.browser.*.
 *
 *              Unrecognized shapes are flattened generically under rflib.platform.*. Blank or
 *              unparseable content yields a single rflib.platform_info entry with the raw string
 *              (or an empty map when blank).
 */
@SuppressWarnings('PMD.ClassNamingConventions')
public with sharing class rflib_PlatformInfoParser {

    private static final String USER_AGENT_KEY = 'user_agent.original';

    /**
     * @description Flattens the event's Platform_Info__c into namespaced typed attributes.
     * @param  evt The log event whose Platform_Info__c should be parsed.
     * @return     Map of attribute name to typed value (Integer/Long/Decimal/Boolean/String).
     */
    public static Map<String, Object> flatten(rflib_Log_Event__e evt) {
        if (evt == null || String.isBlank(evt.Platform_Info__c)) {
            return new Map<String, Object>();
        }

        Object parsed;
        try {
            parsed = JSON.deserializeUntyped(evt.Platform_Info__c);
        } catch (Exception ex) {
            return new Map<String, Object>{ 'rflib.platform_info' => evt.Platform_Info__c };
        }

        if (!(parsed instanceof Map<String, Object>)) {
            return new Map<String, Object>{ 'rflib.platform_info' => evt.Platform_Info__c };
        }

        Map<String, Object> source = (Map<String, Object>) parsed;
        Map<String, Object> result = new Map<String, Object>();

        if (isBrowserInfo(source)) {
            for (String key : source.keySet()) {
                if (key == 'userAgent') {
                    result.put(USER_AGENT_KEY, source.get(key));
                } else {
                    flattenInto(result, 'rflib.browser.' + normalizeKey(key), source.get(key));
                }
            }
        } else if (isApexInfo(source)) {
            for (String key : source.keySet()) {
                flattenInto(result, 'rflib.apex.' + normalizeKey(key), source.get(key));
            }
        } else {
            for (String key : source.keySet()) {
                flattenInto(result, 'rflib.platform.' + normalizeKey(key), source.get(key));
            }
        }

        return result;
    }

    private static Boolean isBrowserInfo(Map<String, Object> source) {
        return source.containsKey('userAgent') || source.containsKey('timing') || source.containsKey('timeOrigin');
    }

    private static Boolean isApexInfo(Map<String, Object> source) {
        // The Apex limits map is flat with only numeric values. Requiring numbers prevents custom
        // flat maps (e.g. {"customer":"acme"} set via rflib_Logger.setPlatformInfo) from being
        // mislabeled as governor-limit data; those fall through to the generic rflib.platform.* branch.
        if (source.isEmpty()) {
            return false;
        }
        for (Object value : source.values()) {
            if (!(value instanceof Integer || value instanceof Long || value instanceof Decimal || value instanceof Double)) {
                return false;
            }
        }
        return true;
    }

    @SuppressWarnings('PMD.ApexDoc')
    private static void flattenInto(Map<String, Object> result, String key, Object value) {
        if (value instanceof Map<String, Object>) {
            Map<String, Object> nested = (Map<String, Object>) value;
            for (String nestedKey : nested.keySet()) {
                flattenInto(result, key + '.' + normalizeKey(nestedKey), nested.get(nestedKey));
            }
        } else if (value instanceof List<Object>) {
            List<Object> items = (List<Object>) value;
            for (Integer i = 0; i < items.size(); i++) {
                flattenInto(result, key + '.' + i, items.get(i));
            }
        } else if (value != null) {
            result.put(key, value);
        }
    }

    /**
     * @description Normalizes a raw key to snake_case: splits camelCase, lowercases, and replaces
     *              any run of non-alphanumeric characters with a single underscore.
     *              "CPU Time" -> "cpu_time", "timeOrigin" -> "time_origin", "domComplete" -> "dom_complete".
     */
    @TestVisible
    private static String normalizeKey(String key) {
        if (String.isBlank(key)) {
            return key;
        }
        // Insert an underscore between a lowercase/digit and a following uppercase letter (camelCase split).
        String withBreaks = key.replaceAll('([a-z0-9])([A-Z])', '$1_$2');
        // Replace any run of non-alphanumeric characters with a single underscore, then lowercase.
        String normalized = withBreaks.replaceAll('[^A-Za-z0-9]+', '_').toLowerCase();
        // Trim leading/trailing underscores.
        return normalized.replaceAll('^_+|_+$', '');
    }
}
