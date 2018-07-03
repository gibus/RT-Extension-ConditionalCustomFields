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
                    if (condition_vals[i].indexOf(conditionedby_vals[j]) != -1) {
                        return !condition_met;
                    }
                } else if (condition_op == "less than") {
                    if (new Intl.Collator(lang, {sensitivity: 'base', numeric: true}).compare(condition_vals[i].toString(), conditionedby_vals[j].toString()) <= 0) {
                        return !condition_met;
                    }
                } else if (condition_op == "greater than") {
                    if (new Intl.Collator(lang, {sensitivity: 'base', numeric: true}).compare(condition_vals[i].toString(), conditionedby_vals[j].toString()) >= 0) {
                        return !condition_met;
                    }
                } else if (condition_op == "between") {
                    if (j == 0 && new Intl.Collator(lang, {sensitivity: 'base', numeric: true}).compare(condition_vals[i].toString(), conditionedby_vals[j].toString()) < 0) {
                        return !condition_met;
                    } else if (j == 1 && new Intl.Collator(lang, {sensitivity: 'base', numeric: true}).compare(condition_vals[i].toString(), conditionedby_vals[j].toString()) > 0) {
                        return !condition_met;
                    }
                }
            }
        }
    }

    return condition_met;
}
