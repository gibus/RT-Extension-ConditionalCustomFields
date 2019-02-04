function activate_datepicker() {
    var opts = {
        dateFormat: 'yy-mm-dd',
        constrainInput: false,
        showButtonPanel: true,
        changeMonth: true,
        changeYear: true,
        showOtherMonths: true,
        showOn: 'none',
        selectOtherMonths: true
    };
    jQuery(".conditioned-by-admin-vals input.datepicker").focus(function() {
        var val = jQuery(this).val();
        if ( !val.match(/[a-z]/i) ) {
            jQuery(this).datepicker('show');
        }
    });
    jQuery(".conditioned-by-admin-vals input.datepicker:not(.withtime)").datepicker(opts);
    jQuery(".conditioned-by-admin-vals input.datepicker.withtime").datetimepicker( jQuery.extend({}, opts, {
        stepHour: 1,
        // We fake this by snapping below for the minute slider
        //stepMinute: 5,
        hourGrid: 6,
        minuteGrid: 15,
        showSecond: false,
        timeFormat: 'HH:mm:ss'
    }) ).each(function(index, el) {
        var tp = jQuery.datepicker._get( jQuery.datepicker._getInst(el), 'timepicker');
        if (!tp) return;
        if (tp._base_injectTimePicker) return; // avoid recursion

        // Hook after _injectTimePicker so we can modify the minute_slider
        // right after it's first created
        tp._base_injectTimePicker = tp._injectTimePicker;
        tp._injectTimePicker = function() {
            this._base_injectTimePicker.apply(this, arguments);

            // Now that we have minute_slider, modify it to be stepped for mouse movements
            var slider = jQuery.data(this.minute_slider[0], "ui-slider");
            slider._base_normValueFromMouse = slider._normValueFromMouse;
            slider._normValueFromMouse = function() {
                var value           = this._base_normValueFromMouse.apply(this, arguments);
                var old_step        = this.options.step;
                this.options.step   = 5;
                var aligned         = this._trimAlignValue( value );
                this.options.step   = old_step;
                return aligned;
            };
        };
    });
}

function naturalSort(a, b, lang) {
    if (window.Intl) {
        if(lang === "") lang = navigator.language;
        return window.Intl.Collator(lang, {sensitivity: 'base', numeric: true}).compare(a.toString(), b.toString());
    }

    /*
     * Natural Sort algorithm for Javascript - Version 0.7 - Released under MIT license
     * Author: Jim Palmer (based on chunking idea from Dave Koelle)
     * http://www.overset.com/2008/09/01/javascript-natural-sort-algorithm-with-unicode-support/
     */
    var re = /(^-?[0-9]+(\.?[0-9]*)[df]?e?[0-9]?$|^0x[0-9a-f]+$|[0-9]+)/gi,
        sre = /(^[ ]*|[ ]*$)/g,
        dre = /(^([\w ]+,?[\w ]+)?[\w ]+,?[\w ]+\d+:\d+(:\d+)?[\w ]?|^\d{1,4}[\/\-]\d{1,4}[\/\-]\d{1,4}|^\w+, \w+ \d+, \d{4})/,
        hre = /^0x[0-9a-f]+$/i,
        ore = /^0/,
        i = function(s) { return (''+s).toLowerCase() || ''+s },
        // convert all to strings strip whitespace
        x = i(a).replace(sre, '') || '',
        y = i(b).replace(sre, '') || '',
        // chunk/tokenize
        xN = x.replace(re, '\0$1\0').replace(/\0$/,'').replace(/^\0/,'').split('\0'),
        yN = y.replace(re, '\0$1\0').replace(/\0$/,'').replace(/^\0/,'').split('\0'),
        // numeric, hex or date detection
        xD = parseInt(x.match(hre)) || (xN.length != 1 && x.match(dre) && Date.parse(x)),
        yD = parseInt(y.match(hre)) || xD && y.match(dre) && Date.parse(y) || null,
        oFxNcL, oFyNcL;
    // first try and sort Hex codes or Dates
    if (yD)
        if ( xD < yD ) return -1;
    else if ( xD > yD ) return 1;
    // natural sorting through split numeric strings and default strings
    for(var cLoc=0, numS=Math.max(xN.length, yN.length); cLoc < numS; cLoc++) {
        // find floats not starting with '0', string or 0 if not defined (Clint Priest)
        oFxNcL = !(xN[cLoc] || '').match(ore) && parseFloat(xN[cLoc]) || xN[cLoc] || 0;
        oFyNcL = !(yN[cLoc] || '').match(ore) && parseFloat(yN[cLoc]) || yN[cLoc] || 0;
        // handle numeric vs string comparison - number < string - (Kyle Adams)
        if (isNaN(oFxNcL) !== isNaN(oFyNcL)) { return (isNaN(oFxNcL)) ? 1 : -1; }
        // rely on string comparison if different types - i.e. '02' < 2 != '02' < '2'
        else if (typeof oFxNcL !== typeof oFyNcL) {
            oFxNcL += '';
            oFyNcL += '';
        }
        if (oFxNcL < oFyNcL) return -1;
        if (oFxNcL > oFyNcL) return 1;
    }
    return 0;
}

function condition_is_met(conditionedby_vals, condition_vals, condition_op, lang) {
    lang = (typeof lang !== 'undefined') ? lang : 'en';
    var condition_met = false;

    if (condition_op == "isn't" || condition_op == "doesn't match" || condition_op == "between") {
        condition_met = true;
    }

    if (condition_vals.length) {
        for (var i=0; i<condition_vals.length; i++) {
            for (var j=0; j<conditionedby_vals.length; j++) {
                if (condition_op == "is" || condition_op == "isn't") {
                    if (condition_vals[i] == conditionedby_vals[j]) {
                        return !condition_met;
                    }
                } else if (condition_op == "matches" || condition_op == "doesn't match") {
                    var regexp = RegExp(conditionedby_vals[j].replace(/[-\/\\^$*+?.()|[\]{}]/g, '\\$&'), "i");
                    if (condition_vals[i].search(regexp) != -1) {
                        return !condition_met;
                    }
                } else if (condition_op == "less than") {
                    if (naturalSort(condition_vals[i], conditionedby_vals[j], lang) <= 0) {
                        return !condition_met;
                    }
                } else if (condition_op == "greater than") {
                    if (naturalSort(condition_vals[i], conditionedby_vals[j], lang) >= 0) {
                        return !condition_met;
                    }
                } else if (condition_op == "between") {
                    var comp = naturalSort(condition_vals[i], conditionedby_vals[j], lang);
                    if (j == 0 && comp < 0) {
                        return !condition_met;
                    } else if (j == 1 && comp > 0) {
                        return !condition_met;
                    }
                }
            }
        }
    }

    return condition_met;
}
