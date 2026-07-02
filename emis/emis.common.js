
var ajaxRequest = function (url, method, options, callback) {
    var defaults = {
        disableCache: true,
        //dataType: 'JSON',
        //contentType: 'application/json; charset=UTF-8',
        enableLadda: false,
        targetLaddaElement: null,
        data: null
    }
    var opts = $.extend({}, defaults, options);
    var laddaElements = [];
    $.ajax({
        url: url,
        method: method,
        dataType: opts.dataType,
        contentType: opts.contentType,
        data: opts.data,
        cache: !opts.disableCache,
        async: true,
        beforeSend: function (n, t) {
            if (opts.enableLadda && opts.targetLaddaElement != null) {
                $(opts.targetLaddaElement).each(function (index, item) {
                    var laddaElement = Ladda.create(item);
                    laddaElement.start();
                    laddaElements.push(laddaElement);
                });

            }
        },
        complete: function (n, t) {
            if (opts.enableLadda && opts.targetLaddaElement != null) {
                $(laddaElements).each(function (index, item) {
                    item.stop();
                });
            }
        },
        success: function (response) {
            if ($.isFunction(callback)) {
                callback(response);
            } else {
                console.log('Invalid callback function set.');
            }
        },
        error: function (xhrResponse) {
            if ($.isFunction(callback)) {
                callback({ IsError: true, IsRedirect: false, Message: xhrResponse.error, IsServerError: true });
            } else {
                console.log('Invalid callback function set.');
            }
        }
    });
};

ko.bindingHandlers.inputmask = {
    init: function (element, valueAccessor, allBindingsAccessor) {
        var mask = valueAccessor();
        var observable = mask.value;
        if (ko.isObservable(observable)) {
            $(element).on('focusout change', function () {
                if ($(element).inputmask('isComplete')) {
                    observable($(element).val());
                } else {
                    observable(null);
                }
            });
        }

        $(element).inputmask(mask);
    },
    update: function (element, valueAccessor, allBindings, viewModel, bindingContext) {
        var mask = valueAccessor();
        var observable = mask.value;
        if (ko.isObservable(observable)) {
            var valuetoWrite = observable();
            $(element).val(valuetoWrite);
        }
    }
};


ko.bindingHandlers.chosen = {
    init: function (element, valueAccessor, allBindings) {
        $(element).chosen(valueAccessor());
        // trigger chosen:updated event when the bound value or options changes

        $.each('value|selectedOptions|options'.split("|"), function (i, e) {
            var bv = allBindings.get(e);
            if (ko.isObservable(bv))
                bv.subscribe(function () { $(element).trigger('chosen:updated'); });
        });

        ko.utils.domNodeDisposal.addDisposeCallback(element, function () {
            // This will be called when the element is removed by Knockout or
            // if some other part of your code calls ko.removeNode(element)
            $(element).chosen("destroy");
        });
    },
    update: function (element) {
        $(element).trigger('chosen:updated');
    }
};

emis.defaultChosenOption = { allow_single_deselect: true };