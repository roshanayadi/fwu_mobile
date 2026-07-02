$(function () {
    emis.CreateNamespace('registrationReport');

    (function (context) {

        context.Title = 'Registration Report';
        context.ViewModel = {};

        context.Mapping = {
            create: function (options) {
                var vm = ko.mapping.fromJS(options.data);

                vm.SearchClick = function () {
                    context.Search();
                    //context.SearchViewRegCard();
                }

                vm.RenderComplete = function () {
                    console.log('validate');
                    context.ApplyValidation();
                    //context.ApplyViewRegCardSearchValidation();
                }

                vm.SelectAll = ko.observable(false);

                vm.SelectAll.subscribe(function (newValue) {
                    context.SelectAll(newValue);
                });

                vm.SearchViewModel.CollegeId.subscribe(function (newCollegeId) {
                    ajaxRequest('/Lookup/GetProgramByCollege', 'POST', { data: { collegeId: newCollegeId } }, function (response) {
                        if (response.IsSuccess) {
                            vm.SearchViewModel.Programs(response.Data);
                        } else {
                            vm.SearchViewModel.Programs([]);
                            showMessage(context.Title, response.Message, 'error');
                        }
                    });
                });

                vm.ViewRegistrationCardClick = function () {
                    context.ViewRegistrationCard();
                }

                vm.PrintClick = function () {
                    context.PrintRegistrationCard();
                }

                return vm;
            }
        }

        context.SelectAll = function (newValue) {
            //$(context.ViewModel.SearchViewModel.Records()).each(function (index, item) {
            //    item.IsSelected(newValue);
            //});
        }


        context.ApplyValidation = function () {
            $('#registrationTriplicateForm').validate({
                rules: {
                    AcademicYearId: {
                        required: true
                    },
                    CollegeId: {
                        required: true
                    }
                },
                messages: {
                    AcademicYearId: {
                        required: 'Academic Year must be selected'
                    },
                    CollegeId: {
                        required: 'College must be selected.'
                    }
                }
            });
        }

        context.Initialize = function () {
            ajaxRequest('/Report/Registration/Initialize', 'GET', {}, function (response) {
                if (response.IsSuccess) {

                    if (!ko.dataFor($('#mainContent')[0])) {
                        context.ViewModel = ko.mapping.fromJS(response.Data, context.Mapping);

                        ko.applyBindings(context.ViewModel, $('#mainContent')[0]);
                    } else {
                        ko.mapping.fromJS(response.Data, context.Mapping, context.ViewModel);
                    }

                } else {
                    showMessage(context.Title, response.Message, 'error');
                }
            });
        }


        context.Search = function () {

            if (!$('#registrationTriplicateForm').valid()) {
                return false;
            }
            var model = ko.toJS(context.ViewModel.SearchViewModel);

            ajaxRequest('/Report/Registration/Index', 'POST', { data: { model: model } }, function (response) {
                if (response.IsSuccess) {
                    ko.mapping.fromJS(response.Data, {}, context.ViewModel.Records);
                } else {
                    showMessage(context.Title, response.Message, 'error');
                }
            });
        }

        //student count report

        context.InitializeStudentCountReport = function () {
            ajaxRequest('/Report/Registration/InitializeStudentCount', 'GET', {}, function (response) {
                if (response.IsSuccess) {

                    if (!ko.dataFor($('#mainContent')[0])) {
                        context.ViewModel = ko.mapping.fromJS(response.Data, context.StudentCountMapping);

                        ko.applyBindings(context.ViewModel, $('#mainContent')[0]);
                    } else {
                        ko.mapping.fromJS(response.Data, context.StudentCountMapping, context.ViewModel);
                    }

                } else {
                    showMessage(context.Title, response.Message, 'error');
                }
            });
        }

        context.ApplyStudentCountValidation = function () {
            $('#registrationTriplicateForm').validate({
                rules: {
                    AcademicYearId: {
                        required: true
                    },
                },
                messages: {
                    AcademicYearId: {
                        required: 'Academic Year must be selected'
                    }
                }
            });
        }

        context.StudentCountMapping = {
            create: function (options) {
                var vm = ko.mapping.fromJS(options.data);

                vm.SearchStudentCountClick = function () {
                    context.SearchStudentCount();
                }

                vm.ExportStudentCountClick = function () {
                    var html = document.querySelector("#table").outerHTML;
                    export_table_to_csv(html, 'report.csv');
                    //$('#table').table2CSV({
                    //    separator: ';',
                    //});
                }

                vm.TotalStudentCountReport = ko.computed(function () {
                    var records = ko.toJS(vm.CollegewiseCountRecord);;
                    var maleSum = 0;
                    var femaleSum = 0;
                    if (records != null && $.isArray(records)) {
                        $(records).each(function (index, item) {
                            maleSum += item.MaleCount;
                            femaleSum += item.FemaleCount;
                        });
                    }
                    return ko.mapping.fromJS({ MaleSum: maleSum, FemaleSum: femaleSum });
                });

                vm.RenderComplete = function () {
                    context.ApplyStudentCountValidation();
                    //context.ApplyViewRegCardSearchValidation();
                }

                vm.SearchViewModel.CollegeId.subscribe(function (newCollegeId) {
                    ajaxRequest('/Lookup/GetProgramByCollege', 'POST', { data: { collegeId: newCollegeId } }, function (response) {
                        if (response.IsSuccess) {
                            vm.SearchViewModel.Programs(response.Data);
                        } else {
                            vm.SearchViewModel.Programs([]);
                            showMessage(context.Title, response.Message, 'error');
                        }
                    });
                });

                return vm;
            }
        }


        context.SearchStudentCount = function () {
            if (!$('#registrationTriplicateForm').valid()) {
                return false;
            }
            var model = ko.toJS(context.ViewModel.SearchViewModel);

            ajaxRequest('/Report/Registration/SearchCollegewiseCountReport', 'POST', { data: { model: model } }, function (response) {
                if (response.IsSuccess) {
                    ko.mapping.fromJS(response.Data, {}, context.ViewModel.CollegewiseCountRecord);
                } else {
                    showMessage(context.Title, response.Message, 'error');
                }
            });
        }

        //ethnicity count report

        context.InitializeEthnicityCountReport = function () {
            ajaxRequest('/Report/Registration/InitializeEthnicityCountReport', 'GET', {}, function (response) {
                if (response.IsSuccess) {

                    if (!ko.dataFor($('#mainContent')[0])) {
                        context.ViewModel = ko.mapping.fromJS(response.Data, context.EthnicityCountMapping);

                        ko.applyBindings(context.ViewModel, $('#mainContent')[0]);
                    } else {
                        ko.mapping.fromJS(response.Data, context.EthnicityCountMapping, context.ViewModel);
                    }

                } else {
                    showMessage(context.Title, response.Message, 'error');
                }
            });
        }

        context.ApplyEthnicityCountValidation = function () {
            $('#registrationTriplicateForm').validate({
                rules: {
                    AcademicYearId: {
                        required: true
                    },
                },
                messages: {
                    AcademicYearId: {
                        required: 'Academic Year must be selected'
                    }
                }
            });
        }

        context.EthnicityCountMapping = {
            create: function (options) {
                var vm = ko.mapping.fromJS(options.data);

                vm.SearchEthnicityCountClick = function () {
                    context.SearchEthnicityCount();
                }

                vm.TotalStudentCountReport = ko.computed(function () {
                    var records = ko.toJS(vm.CollegewiseCountRecord);;
                    var maleSum = 0;
                    var femaleSum = 0;
                    if (records != null && $.isArray(records)) {
                        $(records).each(function (index, item) {
                            maleSum += item.MaleCount;
                            femaleSum += item.FemaleCount;
                        });
                    }
                    return ko.mapping.fromJS({ MaleSum: maleSum, FemaleSum: femaleSum });
                });

                vm.RenderComplete = function () {
                    context.ApplyEthnicityCountValidation();
                    //context.ApplyViewRegCardSearchValidation();
                }

                vm.SearchViewModel.CollegeId.subscribe(function (newCollegeId) {
                    ajaxRequest('/Lookup/GetProgramByCollege', 'POST', { data: { collegeId: newCollegeId } }, function (response) {
                        if (response.IsSuccess) {
                            vm.SearchViewModel.Programs(response.Data);
                        } else {
                            vm.SearchViewModel.Programs([]);
                            showMessage(context.Title, response.Message, 'error');
                        }
                    });
                });

                return vm;
            }
        }


        context.SearchEthnicityCount = function () {
            if (!$('#registrationTriplicateForm').valid()) {
                return false;
            }
            var model = ko.toJS(context.ViewModel.SearchViewModel);

            ajaxRequest('/Report/Registration/EthnicityCountReport', 'POST', { data: { model: model } }, function (response) {
                if (response.IsSuccess) {
                    ko.mapping.fromJS(response.Data, {}, context.ViewModel.CollegewiseCountRecord);
                } else {
                    showMessage(context.Title, response.Message, 'error');
                }
            });
        }

        //district wise summary report
        context.DistrictWiseReportMapping = {
            create: function (options) {
                var vm = ko.mapping.fromJS(options.data);

                vm.SearchClick = function () {
                    context.SearchDistrictWiseSummaryReport();
                };

                vm.RenderComplete = function () {
                    $('#frm').validate({
                        rules: {
                            AcademicYearId: { required: true }
                        }
                    });
                };

                return vm;
            }
        };
        context.InitializeDistrictWiseSummaryReport = function () {
            ajaxRequest('/Report/Registration/InitializeDistrictWise', 'GET', {}, function (response) {
                if (response.IsSuccess) {
                    if (!ko.dataFor($('#mainContent')[0])) {
                        context.ViewModel.DistrictWiseReportVM = ko.mapping.fromJS(response.Data, context.DistrictWiseReportMapping);
                        ko.applyBindings(context.ViewModel.DistrictWiseReportVM, $('#mainContent')[0]);
                    }
                    else {
                        ko.mapping.fromJS(response.Data, context.ViewModel.DistrictWiseReportVM);
                    }
                } else {
                    showMessage(context.Title, response.Message, 'error');
                }
            });
        };

        context.SearchDistrictWiseSummaryReport = function () {
            if (!$('#frm').valid()) {
                return false;
            }
            var model = ko.mapping.toJS(context.ViewModel.DistrictWiseReportVM).SearchViewModel;
            delete model.Districts;
            delete model.AcademicYears;

            ajaxRequest('/Report/Registration/DistrictWise', 'POST', {
                data: { model: model }
            }, function (response) {
                if (response.IsSuccess) {
                    ko.mapping.fromJS(response.Data, {}, context.ViewModel.DistrictWiseReportVM.Records);
                } else {
                    showMessage(context.Title, response.Message, 'error');
                }
            });
        };

        //college wise summary report
        context.CollegeWiseReportMapping = {
            create: function (options) {
                var vm = ko.mapping.fromJS(options.data);

                vm.SearchClick = function () {
                    context.SearchCollegeWiseSummaryReport();
                };

                vm.SearchViewModel.DistrictId.subscribe(function (newDistrictId) {
                    if (newDistrictId) {
                        ajaxRequest('/Lookup/GetCollegeByDistrict', 'POST', { data: { districtId: newDistrictId } }, function (response) {
                            if (response.IsSuccess) {
                                ko.mapping.fromJS(response.Data, {}, vm.SearchViewModel.Colleges);
                            }
                            else {
                                ko.mapping.fromJS([], {}, vm.SearchViewModel.Colleges);
                            }
                        });
                    }
                })

                vm.RenderComplete = function () {
                    $('#frm').validate({
                        rules: {
                            AcademicYearId: { required: true },
                            DistrictId: { required: true },
                        }
                    });
                };

                return vm;
            }
        };
        context.InitializeCollegeWiseSummaryReport = function () {
            ajaxRequest('/Report/Registration/InitializeCollegeWise', 'GET', {}, function (response) {
                if (response.IsSuccess) {
                    if (!ko.dataFor($('#mainContent')[0])) {
                        context.ViewModel.CollegeWiseReportVM = ko.mapping.fromJS(response.Data, context.CollegeWiseReportMapping);
                        ko.applyBindings(context.ViewModel.CollegeWiseReportVM, $('#mainContent')[0]);
                    }
                    else {
                        ko.mapping.fromJS(response.Data, context.ViewModel.CollegeWiseReportVM);
                    }
                } else {
                    showMessage(context.Title, response.Message, 'error');
                }
            });
        };

        context.SearchCollegeWiseSummaryReport = function () {
            if (!$('#frm').valid()) {
                return false;
            }
            var model = ko.mapping.toJS(context.ViewModel.CollegeWiseReportVM).SearchViewModel;
            delete model.Districts;
            delete model.AcademicYears;

            ajaxRequest('/Report/Registration/CollegeWise', 'POST', {
                data: { model: model }
            }, function (response) {
                if (response.IsSuccess) {
                    ko.mapping.fromJS(response.Data, {}, context.ViewModel.CollegeWiseReportVM.Records);
                } else {
                    showMessage(context.Title, response.Message, 'error');
                }
            });
        };


    })(emis.registrationReport);
});