
$(function () {
    emis.CreateNamespace('collegePaymentDetails');

    (function (context) {

        context.Title = 'College Payment Ledger';
        context.FormId = '#searchForm';

        context.ListMapping = {
            create: function (options) {
                var vm = ko.mapping.fromJS(options.data);

                vm.AcademicYearId.subscribe(function (newValue) {
                    context.LoadExamSchedules(newValue);
                })

                vm.SearchDetails = function () {
                    var model = ko.mapping.toJS(context.ViewModel);
                    var data = {
                        academicYearId: model.AcademicYearId,
                        collegeId: model.CollegeId,
                        examScheduleId: model.ExamScheduleId
                    }

                    ajaxRequest('/Exam/CollegepaymentDetails/getdetails', 'GET', {
                        data: { model: data }
                    }, function (response) {
                        if (response.IsSuccess) {
                            $("#recordContent").dxDataGrid({
                                dataSource: response.Data,
                                showRowLines: true,
                                showBorders: true,
                                columns: [
                                    { dataField: "CollegeTypeName", groupIndex:0 },
                                    { dataField: "CollegeName", },
                                    { dataField: "ExamScheduleName", groupIndex:1    },
                                    { dataField: "Amount" },
                                    {
                                        dataField: "ForwardedTimeStamp",
                                        caption: "Date",
                                        calculateCellValue: function (o) {
                                            return moment(o.ForwardedTimeStamp).format("YYYY-MM-DD");
                                        }
                                    },
                                    { dataField: "StudentCount" },

                                ],
                                paging: {
                                    enable: false
                                }

                            })
                        } else {
                            showMessage(context.Title, response.Message, 'error');
                        }
                    });
                }


                return vm;
            }
        };
        context.LoadExamSchedules = function (newAcademicYearID) {
            if (newAcademicYearID) {
                ajaxRequest('/Lookup/GetExamScheduleByAcademicYear', 'POST', { data: { academicYearId: newAcademicYearID } }, function (response) {
                    var examSchedules = [];
                    if (response.IsSuccess) {
                        examSchedules = response.Data;
                    } else {
                        examSchedules = [];
                    }
                    ko.mapping.fromJS(examSchedules, {}, context.ViewModel.ExamSchedules);
                });
            } else {
                ko.mapping.fromJS([], {}, context.ViewModel.ExamSchedules);

            }
        }

        context.InitializeList = function () {
            ajaxRequest('/Exam/CollegepaymentDetails/initialize', 'GET', {}, function (response) {
                if (response.IsSuccess) {
                    if (!ko.dataFor($('#mainContent')[0])) {
                        context.ViewModel = ko.mapping.fromJS(response.Data, context.ListMapping);

                        ko.applyBindings(context.ViewModel, $('#mainContent')[0]);
                    } else {
                        ko.mapping.fromJS(response.Data, {}, context.ViewModel);
                    }
                } else {
                    showMessage(context.Title, response.Message, 'error');
                }
            });

        }

    })(emis.collegePaymentDetails);
});