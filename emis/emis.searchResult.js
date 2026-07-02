
$(function () {
    emis.CreateNamespace('searchResult');

    (function (context) {

        context.Title = 'Search Result';
        context.FormId = '#searchResultForm';

        context.ViewModel = {
        };

        context.Mapping = {
            create: function (options) {
                var vm = ko.mapping.fromJS(options.data);
                vm.IsResultAvailable = ko.observable(false);
                vm.searchResult = function () {
                    context.validate();
                    if ($("#searchResultForm").valid()) {
                        context.SearchRecords();
                    }
                }
                return vm;
            }
        };

        context.ResultMapping = {
            create: function (options) {
                var vm = ko.mapping.fromJS(options.data);

                vm.IsResultAvailable = ko.observable(false);

                return vm;
            }
        };

        context.validate = function () {
            $("#searchResultForm").validate({
                rules: {
                    ExamScheduleId: {
                        required: true
                    },
                    SymbolNo: {
                        required: true
                    },
                    DateOfBirthBS: {
                        required: true,
                        dateBS: true
                    }
                },
                messages: {
                    AcademicYearId: "Please select a passed year",
                    SymbolNo: {
                        required: "Please enter your symbol number",
                        minlength: "Symbol number must be 8 characters long",
                        maxlength: "Symbol number must be 8 characters long"
                    },
                    DateOfBirthBS: {
                        required: "Please enter your date of birth",
                        dateBS: "Please enter a valid date in the format YYYY/MM/DD"
                    }
                },
                errorElement: "span",
                errorClass: "help-block",
                highlight: function (element) {
                    $(element).closest('.form-group').addClass('has-error');
                },
                unhighlight: function (element) {
                    $(element).closest('.form-group').removeClass('has-error');
                },
                errorPlacement: function (error, element) {
                    if (element.parent('.input-group').length) {
                        error.insertAfter(element.parent());
                    } else {
                        error.insertAfter(element);
                    }
                }
            });

            // Custom method for validating Bikram Sambat date format
            $.validator.addMethod("dateBS", function (value, element) {
                return this.optional(element) || /^\d{4}\/\d{2}\/\d{2}$/.test(value);
            }, "Please enter a valid date in the format YYYY/MM/DD");
        }
        //Index Page Related
        context.Initialize = function (model) {
            if (!ko.dataFor($('#mainContent')[0])) {
                context.ViewModel.SearchViewModel = ko.mapping.fromJS(model, context.Mapping);

                ko.applyBindings(context.ViewModel.SearchViewModel, $('#mainContent')[0]);
            } else {
                ko.mapping.fromJS(model, {}, context.ViewModel.SearchViewModel);
            }
        }

        context.SearchRecords = function () {
            if ($(context.FormId).valid()) {
                var searchModel = ko.mapping.toJS(context.ViewModel.SearchViewModel);
                blockUI();
                ajaxRequest('/Result/Index', 'POST', { data: { model: searchModel } }, function (response) {
                    unblockUI();
                    if (response.IsSuccess && response.Data.StudentName) {
                        if (!ko.dataFor($('#resultContent')[0])) {
                            context.ViewModel.ResultVM = ko.mapping.fromJS(response.Data, context.ResultMapping);
                            ko.applyBindings(context.ViewModel.ResultVM, $('#resultContent')[0]);
                        } else {
                            ko.mapping.fromJS(response.Data, {}, context.ViewModel.ResultVM);
                        }
                        context.ViewModel.ResultVM.IsResultAvailable(true);
                        $('html, body').animate({
                            scrollTop: 600
                        }, 1000);
                    } else {
                        if (!context.ViewModel.ResultVM) {
                            context.ViewModel.ResultVM = ko.mapping.fromJS({}, context.ResultMapping);
                        }
                        ko.mapping.fromJS(response.Data || {}, {}, context.ViewModel.ResultVM);
                        context.ViewModel.ResultVM.IsResultAvailable(false);
                        showMessage("Error", "Result not found.", 'error');
                    }
                });
            }
        }


    })(emis.searchResult);
});