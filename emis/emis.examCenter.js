$(function () {
    emis.CreateNamespace('examCenter');

    (function (context) {

        context.Title = 'Exam Center';
        context.ViewModel = {};
        context.Mapping = {
            create: function (options) {
                var vm = ko.mapping.fromJS(options.data);

                vm.OriginalDetails = ko.observableArray([]);

                vm.ParentExamScheduleID.subscribe(function (newValue) {
                    if (newValue && newValue > 0) {
                        context.GetExamSchedules(newValue)
                    } else {
                        vm.ExamSchedules([]);
                    }
                })

                vm.ExamScheduleID.subscribe(function (newValue) {
                    if (newValue && newValue > 0) {
                        context.GetCenterDetail(newValue, vm.CollegeID(), vm.ProgramId())
                    } else {
                        vm.OriginalDetails([]);
                        vm.Details([]);
                    }
                })

                vm.CollegeID.subscribe(function (newValue) {
                    if (newValue && newValue > 0) {
                        context.GetCenterDetail(vm.ExamScheduleID(), newValue, vm.ProgramId())
                    } else {
                        vm.OriginalDetails([]);
                        vm.Details([]);
                    }
                })

                vm.ProgramId.subscribe(function (newValue) {
                    if (newValue && newValue > 0) {
                        context.GetCenterDetail(vm.ExamScheduleID(), vm.CollegeID(), newValue)
                    } else {
                        vm.OriginalDetails([]);
                        vm.Details([]);
                    }
                })

                vm.FetchCollegeRecords = function ($data) {
                    console.log($data);
                    var collegeId = $data.CollegeId;
                    var examScheduleId = vm.ExamScheduleID();
                    var programId = vm.ProgramId();
                    ajaxRequest('/Exam/ExamCenter/GetCollegeDetail', 'GET', { data: { programId: programId, collegeId: collegeId, examScheduleId: examScheduleId } }, function (response) {
                        var copy = ko.toJS(ko.mapping.fromJS($data))// $.extend({}, $data);
                        if (response.IsSuccess) {
                            $data.Count(response.Data.Count)
                            $data.SavedRollNoFrom(response.Data.SavedRollNoFrom)
                            $data.SavedRollNoTo(response.Data.SavedRollNoTo)
                            $data.RollNoFrom(response.Data.RollNoFrom)
                            $data.RollNoTo(response.Data.RollNoTo)

                        } else {

                            $data.Count('')
                            $data.SavedRollNoFrom('')
                            $data.SavedRollNoTo('')
                            $data.RollNoFrom('')
                            $data.RollNoTo('')

                            showMessage(context.Title, response.Message, 'error', function (response) {

                            })
                        }
                        var result = ko.mapping.fromJS($data);
                        vm.Details.replace(copy, result)
                    })
                }

                vm.AddNewClick = function () {
                    vm.Details.push(ko.mapping.fromJS(ko.mapping.toJS(vm.DetailTemplate)))
                }

                vm.RemoveRowClick = function ($data) {
                    vm.Details.remove($data);
                }

                vm.ReloadSavedDetailsClick = function () {
                    ko.mapping.fromJS(ko.mapping.toJS(vm.OriginalDetails), vm.Details);
                }

                vm.Save = function () {
                    context.Save(true)
                }

                vm.SaveOnly = function () {
                    context.Save(false);
                }


                return vm;
            }
        };

        context.GetCenterDetail = function (examScheduleId, collegeId, programId) {
            if (examScheduleId > 0 && collegeId > 0 && programId > 0) {
                ajaxRequest('/Exam/ExamCenter/GetCenterDetail', 'GET', { data: { programId: programId, collegeId: collegeId, examScheduleId: examScheduleId } }, function (response) {
                    if (response.IsSuccess) {
                        ko.mapping.fromJS(response.Data.Records, {}, context.ViewModel.AddNewModel.Details)
                        context.ViewModel.AddNewModel.Code(response.Data.ExamCenterCode)
                        context.ViewModel.AddNewModel.OriginalDetails(response.Data);

                    } else {
                        context.ViewModel.AddNewModel.Details([]);
                        context.ViewModel.AddNewModel.OriginalDetails([]);
                        showMessage(context.Title, response.Message, 'error', function (response) {

                        })
                    }
                })
            } else {
                context.ViewModel.AddNewModel.OriginalDetails([]);
                context.ViewModel.AddNewModel.Details([]);
            }
        }

        context.GetExamSchedules = function (parentExamScheduleId) {
            if (parentExamScheduleId > 0) {
                ajaxRequest('/lookup/GetExamSchedulesByParent', 'post', { data: { id: parentExamScheduleId } }, function (response) {
                    if (response.IsSuccess) {
                        ko.mapping.fromJS(response.Data, {}, context.ViewModel.AddNewModel.ExamSchedules)
                    } else {
                        ko.mapping.fromJS([], {}, context.ViewModel.AddNewModel.ExamSchedules)
                        showMessage(context.Title, response.Message, 'error', function (response) {

                        })
                    }
                })
            } else {
                context.ViewModel.AddNewModel.OriginalDetails([]);
                context.ViewModel.AddNewModel.Details([]);
            }
        }
        //context.ApplyCenterOnly = function () {
        //    swal({
        //        title: "Approve Student",
        //        text: "Are you sure you want to apply exam center as per this. ",
        //        type: "warning",
        //        showCancelButton: true,
        //        confirmButtonColor: "#DD6B55",
        //        confirmButtonText: "Yes, Approve Student Application",
        //        cancelButtonText: "Cancel",
        //        closeOnConfirm: true,
        //        closeOnCancel: false
        //    },
        //        function (isConfirm) {
        //            if (isConfirm) {

        //                ajaxRequest('/Exam/Registration/Approve', 'POST', { data: { id: id } }, function (response) {
        //                    if (response.IsSuccess) {
        //                        showMessage(context.Title, response.Message, 'success', null, 'swal')
        //                        context.ViewModel.ExamRegistrationIndexVM.SearchClick();
        //                        //
        //                    } else {
        //                        showMessage(context.Title, response.Message, 'error', null, 'swal')
        //                        //
        //                    }
        //                })
        //            } else {
        //                swal("Cancelled", "Approve Student has ben cancelled.", "error");
        //            }
        //        });
        //}

        context.Save = function (applyCenter) {
            if (!$('#frm').valid()) {
                return false;
            }
            var model = ko.mapping.toJS(context.ViewModel.AddNewModel);
            delete model.Colleges;
            delete model.Programs;
            delete model.ExamSchedules;
            ajaxRequest('/Exam/ExamCenter/Create', 'POST',
                {
                    data: { model: model, applyCenter: applyCenter },
                    enableLadda: true,
                    targetLaddaElement: '[data-button-type=ladda]'
                }, function (response) {
                    if (response.IsSuccess) {
                        showMessage(context.Title, response.Message, 'success', function () {
                        });
                    } else {
                        showMessage(context.Title, response.Message, 'error');
                    }
                });
        }

        context.Initialize = function (model) {
            if (!ko.dataFor($('#mainContent')[0])) {
                context.ViewModel.AddNewModel = ko.mapping.fromJS(model, context.Mapping);

                ko.applyBindings(context.ViewModel.AddNewModel, $('#mainContent')[0]);//subjectDetailModal
            } else {
                ko.mapping.fromJS(model, context.Mapping, context.ViewModel.AddNewModel);
            }
        }

        ///
        ///Import
        context.ImportMapping = {
            create: function (options) {
                var vm = ko.mapping.fromJS(options.data);

                vm.OriginalDetails = ko.observableArray([]);

                vm.Save = function () {
                }


                return vm;
            }
        };
        context.InitializeImport = function (model) {
            if (!ko.dataFor($('#mainContent')[0])) {
                context.ViewModel.ImportVM = ko.mapping.fromJS(model, context.ImportMapping);

                ko.applyBindings(context.ViewModel.ImportVM, $('#mainContent')[0]);//subjectDetailModal
            } else {
                ko.mapping.fromJS(model, context.Mapping, context.ViewModel.ImportVM);
            }
        }
    })(emis.examCenter);
});