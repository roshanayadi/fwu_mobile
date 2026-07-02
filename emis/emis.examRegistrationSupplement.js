$(function () {
    emis.CreateNamespace('examRegistrationSupplement');

    (function (context) {

        context.Title = 'Exam Registration';
        context.CreateFormId = '#frm';
        context.CreateSearchFormId = '#searchForm';

        context.ViewModel = {
            ExamRegistrationCreateVM: {
                create: function (options) {
                    var vm = ko.mapping.fromJS(options.data);

                    vm.SearchSupplementRecord = function () {
                        context.SearchSupplementRecord();
                    };

                    vm.RenderComplete = function () {
                        $('#searchForm').validate({
                            rules: {
                                SymbolNo: {
                                    required: true
                                }
                            },
                            messages: {
                                SymbolNo: {
                                    required: 'Please Enter Symbol No First'
                                }
                            }
                        });
                    }
                    return vm;
                }
            },
        };

        //create related
        context.SaveExamRegistration = function () {
            var searchModel = ko.toJS(context.ViewModel.ExamRegistrationCreateVM.SearchModel);
            var saveContent = ko.toJS(context.ViewModel.ExamRegistrationCreateVM.CreateContent);

            delete searchModel.__ko_mapping__;
            delete saveContent.__ko_mapping__;
            ajaxRequest('/Exam/Registration/Create', 'POST', { data: { filterModel: searchModel, contentModel: saveContent } }, function (response) {
                if (response.IsSuccess) {
                    showMessage(context.Title, response.Message, 'success', function () {
                        window.location = '/Exam/Registration/Index';
                    });
                } else {
                    showMessage(context.Title, response.Message, 'error', function () { }, true);
                }
            });
        }

        context.ExamRegistrationCreateMapping = {
            create: function (options) {
                var vm = ko.mapping.fromJS(options.data);

                vm.SearchSupplementRecord = function () {
                    context.SearchSupplementRecord();
                }

              

                return vm;
            }
        }

        context.ExamRegistrationEntryMapping = {
            create: function (options) {
                var vm = ko.mapping.fromJS(options.data);

                vm.SelectAll = ko.observable(false);


                vm.SaveExamRegistration = function () {
                    context.SaveExamRegistration();
                };

                vm.SelectAll.subscribe(function (newValue) {
                    $($(vm.Records()).toArray()).each(function (index, item) {
                        item.IsRegistered(newValue)
                    });

                });

                return vm;
            }
        }

        context.SearchSupplementRecord = function () {
            if (!$('#searchForm').valid()) {
                return false;
            }
            var searchModel = ko.mapping.toJS(context.ViewModel.ExamRegistrationCreateVM.SearchModel);
            ajaxRequest('/Exam/Registration/SearchSupplementRecord', 'GET', { data: { symbolNo: searchModel.SymbolNo } }, function (response) {
                if (response.IsSuccess) {
                    if (!ko.dataFor($('#entryContent')[0])) {
                        context.ViewModel.ExamRegistrationCreateVM.EntryVM = ko.mapping.fromJS({ Records: response.Data }, context.ExamRegistrationEntryMapping);
                        ko.applyBindings(context.ViewModel.ExamRegistrationCreateVM.EntryVM, $('#entryContent')[0]);
                    }
                    else {
                        ko.mapping.fromJS({ Records: response.Data }, {}, context.ViewModel.ExamRegistrationCreateVM.EntryVM);
                    }
                }
                else {
                    ko.mapping.fromJS(response.Data, {}, {});
                    showMessage(context.Title, response.Message, 'error')
                }
            });
        }

        context.Initialize = function () {
            var model = {
                SymbolNo: ''
            };
            if (!ko.dataFor($('#mainContent')[0])) {
                context.ViewModel.ExamRegistrationCreateVM.SearchModel = ko.mapping.fromJS(model, context.ExamRegistrationCreateMapping);

                ko.applyBindings(context.ViewModel.ExamRegistrationCreateVM, $('#mainContent')[0]);
            } else {
                ko.mapping.fromJS(model, context.ExamRegistrationCreateMapping, context.ViewModel.ExamRegistrationCreateVM.SearchModel);
            }
            $('#entryContent').html('')
            ko.cleanNode($('#entryContent')[0])
        }

        context.SaveExamRegistration = function () {
            var records = ko.toJS(context.ViewModel.ExamRegistrationCreateVM.EntryVM.Records);
            var symbolNo = context.ViewModel.ExamRegistrationCreateVM.SearchModel.SymbolNo();
            ajaxRequest('/Exam/Registration/Supplement', 'POST', { data: { records: records, symbolNo: symbolNo } }, function (response) {
                if (response.IsSuccess) {
                    context.Initialize();
                    showMessage(context.Title, response.Message, 'success')
                }
                else {
                    showMessage(context.Title, response.Message, 'error')

                }
            });
        }

        //supplement report
        context.ReportMapping = {
            create: function (options) {
                var vm = ko.mapping.fromJS(options.data);

                vm.Search = function () {
                    context.SearchSupplementRegistration();
                }

                vm.Export = function () {
                    context.SearchSupplementRegistration(true);

                }

                vm.RenderComplete = function () {
                    $('#searchForm').validate({
                        rules: {
                            DistrictId: { required: true }
                        },
                        messages: {
                            DistrictId: { required: 'District must be selected.' }

                        }
                    });
                }

                vm.DistrictId.subscribe(function (newValue) {
                    if (newValue) {
                        ajaxRequest('/Lookup/GetCollegeByDistrict', 'POST', { data: { districtId: newValue } }, function (response) {
                            var colleges = [];
                            if (response.IsSuccess) {
                                colleges = response.Data;
                            }
                            else {
                                showMessage(context.Title, response.Message, 'error');
                            }
                            ko.mapping.fromJS(colleges, {}, context.ViewModel.ReportViewModel.Colleges);
                        })
                    }
                    else {
                        ko.mapping.fromJS([], {}, context.ViewModel.ReportViewModel.Colleges);
                    }
                })
                return vm;
            }
        }

        context.InitializeReport = function (data) {
            context.ViewModel.ReportViewModel = ko.mapping.fromJS(data, context.ReportMapping);
            ko.applyBindings(context.ViewModel.ReportViewModel, $('#mainContent')[0]);
        }

        context.SearchSupplementRegistration = function (isExport) {
            if (!$('#searchForm').valid()) {
                return false;
            }
            var vm = ko.mapping.toJS(context.ViewModel.ReportViewModel);
            ajaxRequest('/Report/ExamRegistration/Supplement', 'POST', { data: { model: vm, isExport: isExport } }, function (response) {
                console.log(response);
                var records = [];
                if (response.IsSuccess) {
                    records = response.Data;
                }
                else {
                    showMessage(context.Title, response.Message, 'error');
                }
                if (isExport) {
                    window.open('/Report/ExamRegistration/Export')
                }
                if (!ko.dataFor($('#reportContent')[0])) {
                    context.ViewModel.ReportViewModel.Records = ko.mapping.fromJS(records);
                    ko.applyBindings(context.ViewModel.ReportViewModel, $('#reportContent')[0]);
                }
                else {
                    ko.mapping.fromJS(records, {}, context.ViewModel.ReportViewModel.Records);
                }
            });
        }

    })(emis.examRegistrationSupplement);
});