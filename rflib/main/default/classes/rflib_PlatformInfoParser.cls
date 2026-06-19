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

    // Distinctive keys always present in the Apex governor-limit map produced by rflib_DefaultLogger.
    // Detecting the Apex shape by these known keys (rather than "all values are numeric") prevents
    // all-numeric custom metadata such as {"duration_ms":42} from being misclassified as
    // governor-limit data; unknown shapes fall through to the generic rflib.platform.* namespace.
    private static final Set<String> APEX_SIGNATURE_KEYS = new Set<String>{ 'CPU Time', 'Heap Size' };

    // Hard cap on the number of flattened leaves. A valid but pathological Platform_Info__c (e.g. a
    // large JSON array within the 32 KB field limit) would otherwise allocate — and the callers sort —
    // thousands of keys before any per-destination cap runs, risking Apex heap/CPU across a bulkified
    // platform-event flow. Flattening stops (iteration and allocation both) once this many leaves exist;
    // a rflib.platform_info.truncated marker records that some were dropped. Set above the destination
    // caps (~100) so normal payloads are unaffected and destinations remain the output-truncation owner.
    @TestVisible
    private static final Integer MAX_FLATTENED_KEYS = 500;

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

        Boolean browser = isBrowserInfo(source);
        String prefix = browser ? 'rflib.browser.' : (isApexInfo(source) ? 'rflib.apex.' : 'rflib.platform.');

        for (String key : source.keySet()) {
            if (result.size() >= MAX_FLATTENED_KEYS) {
                break;
            }
            if (browser && key == 'userAgent') {
                result.put(USER_AGENT_KEY, source.get(key));
            } else {
                flattenInto(result, prefix + normalizeKey(key), source.get(key));
            }
        }

        if (result.size() >= MAX_FLATTENED_KEYS) {
            result.put(
                'rflib.platform_info.truncated',
                'Platform info exceeded ' + MAX_FLATTENED_KEYS + ' attributes; remainder dropped'
            );
        }

        return result;
    }

    private static Boolean isBrowserInfo(Map<String, Object> source) {
        return source.containsKey('userAgent') || source.containsKey('timing') || source.containsKey('timeOrigin');
    }

    private static Boolean isApexInfo(Map<String, Object> source) {
        // Classify as the Apex governor-limit map only when its distinctive limit keys are present,
        // so arbitrary custom metadata (including all-numeric maps) is not labeled as rflib.apex.*.
        return source.keySet().containsAll(APEX_SIGNATURE_KEYS);
    }

    @SuppressWarnings('PMD.ApexDoc')
    private static void flattenInto(Map<String, Object> result, String key, Object value) {
        // The in-loop cap checks stop iteration once MAX_FLATTENED_KEYS leaves exist, so a pathological
        // structure cannot allocate or iterate without bound; flatten() then records a truncation marker.
        if (value instanceof Map<String, Object>) {
            Map<String, Object> nested = (Map<String, Object>) value;
            for (String nestedKey : nested.keySet()) {
                if (result.size() >= MAX_FLATTENED_KEYS) {
                    return;
                }
                flattenInto(result, key + '.' + normalizeKey(nestedKey), nested.get(nestedKey));
            }
        } else if (value instanceof List<Object>) {
            List<Object> items = (List<Object>) value;
            for (Integer i = 0; i < items.size(); i++) {
                if (result.size() >= MAX_FLATTENED_KEYS) {
                    return;
                }
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
