$(function () {
    emis.CreateNamespace('internalMarks');

    (function (context) {

        context.Title = 'Internal Marks';
        context.ViewModel = {
            CreateModel: {
                SaveInternalMarks: function () {
                    context.Save();
                },
               
            },

        };

        context.SetupAutoFocus = function () {
            $('input.theoryMarks').keyup(function () {
                if ($(this).val().length == 2) {
                    var nextelement = $('input.theoryMarks').eq(($('input.theoryMarks').index($(this)) + 1));
                    $(nextelement).focus();
                }
            });
        }

        context.Mapping = {
            create: function (options) {
                var vm = ko.mapping.fromJS(options.data);

                vm.SearchViewModel.LevelId.subscribe(function (newValue) {
                    context.LoadProgramForList(vm.SearchViewModel.CollegeId(), newValue);
                });
                vm.SearchViewModel.CollegeId.subscribe(function (newValue) {
                    context.LoadProgramForList(newValue, vm.SearchViewModel.LevelId());
                });

                vm.SearchViewModel.ProgramId.subscribe(function (newProgramId) {
                    context.LoadYearPartsForList(newProgramId);
                });


                vm.SearchViewModel.YearPartId.subscribe(function () {
                    context.LoadSubjectsForList();
                });

                vm.SearchViewModel.Search = function () {
                    context.SearchListRecords();
                }

                vm.SubjectRecords = ko.computed(function () {
                    var groups = [];
                    ko.utils.arrayForEach(vm.Records(), function (r) {
                        var g = ko.utils.arrayFirst(groups, function (g) {
                            return g.SubjectName() === r.SubjectName()
                                && g.InternalPracticalFullMark() === r.InternalPracticalFullMark()
                                && g.InternalPracticalPassMark() === r.InternalPracticalPassMark()
                                && g.InternalTheoryFullMark() === r.InternalTheoryFullMark()
                                && g.InternalTheoryPassMark() === r.InternalTheoryPassMark()
                                && g.SubjectDetailId() === r.SubjectDetailId()
                                && g.HasPractical() === r.HasPractical()
                                ;
                        });
                        if (!g) {
                            g = {
                                SubjectName: r.SubjectName,
                                InternalPracticalFullMark: r.InternalPracticalFullMark,
                                InternalPracticalPassMark: r.InternalPracticalPassMark,
                                InternalTheoryFullMark: r.InternalTheoryFullMark,
                                InternalTheoryPassMark: r.InternalTheoryPassMark,
                                SubjectDetailId: r.SubjectDetailId,
                                HasPractical: r.HasPractical,
                                Records: ko.observableArray([])
                            };
                            groups.push(g);
                        }
                        g.Records.push(r);
                    });
                    return groups;
                });

                vm.StudentRecords = ko.computed(function () {
                    var groups = [];
                    ko.utils.arrayForEach(vm.Records(), function (r) {
                        var g = ko.utils.arrayFirst(groups, function (g) {
                            return g.RegistrationNo() === r.RegistrationNo()
                                && g.Name() === r.Name()
                                ;
                        });
                        if (!g) {
                            g = {
                                RegistrationNo: r.RegistrationNo,
                                Name: r.Name,
                                Records: ko.observableArray([])
                            };
                            groups.push(g);
                        }


                        g.Records.push(r);
                    });

                    return groups;
                });


                vm.StudentGroupedRecords = ko.computed(function () {
                    var result = [];
                    var subjectRecords = ko.toJS(vm.SubjectRecords());
                    $(vm.StudentRecords()).each(function (index, item) {
                        var subjects = [];
                        $(subjectRecords).each(function (index1, item1) {
                            var subject = {
                                SubjectDetailId: item1.SubjectDetailId,
                                SubjectName: item1.SubjectName,
                                HasPractical: item1.HasPractical
                            }
                            var marksRecord = $(item1.Records).filter(function (i, l) {
                                return l.SubjectDetailId === subject.SubjectDetailId &&
                                    l.RegistrationNo === item.RegistrationNo();
                            });
                            if (marksRecord != null && marksRecord.length == 1) {
                                subject.OMThInternal = marksRecord[0].OMThInternal;
                                subject.OMPrInternal = marksRecord[0].OMPrInternal;
                            } else {
                                subject.OMThInternal = null;
                                subject.OMPrInternal = null;
                            }
                            subjects.push(ko.mapping.fromJS(subject));
                        });
                        item.SubjectRecords = ko.observableArray(subjects);
                        result.push(item);
                    });
                    return (result);
                });

                vm.Print = function () {
                    context.PrintLedger();
                }

                return vm;
            }
        };

        context.SearchListRecords = function () {
            if (!$('#listForm').valid()) {
                return false;
            }
            var model = ko.toJS(context.ViewModel.ListModel.SearchViewModel);
            delete model.YearParts;
            delete model.Programs;
            delete model.AcademicYears;
            delete model.Colleges;
            delete model.Subjects;
            delete model.Search;

            ajaxRequest('/Exam/InternalMarks/Index',
                'POST',
                { data: { model: model } },
                function (response) {
                    if (response.IsSuccess) {
                        ko.mapping.fromJS(response.Data, {}, context.ViewModel.ListModel.Records);


                    } else {
                        showMessage(context.Title, response.Message, 'error');
                    }
                });
        }

        context.LoadProgramForList = function (newCollegeId, newLevelId) {
            if (newCollegeId > 0 && newLevelId > 0) {
                ajaxRequest('/Lookup/GetProgramByCollege', 'POST', { data: { collegeId: newCollegeId, levelId: newLevelId } }, function (response) {
                    var programs = [];
                    if (response.IsSuccess) {
                        programs = response.Data;
                    } else {
                        programs = [];
                    }
                    ko.mapping.fromJS(programs, {}, context.ViewModel.ListModel.SearchViewModel.Programs);
                });
            } else {
                ko.mapping.fromJS([], {}, context.ViewModel.ListModel.SearchViewModel.Programs);
            }
        }

        context.LoadYearPartsForList = function (newProgramId) {
            if (newProgramId > 0) {
                ajaxRequest('/Lookup/GetYearPartByProgram', 'POST', { data: { programId: newProgramId } }, function (response) {
                    var yearParts = [];
                    if (response.IsSuccess) {
                        yearParts = response.Data;
                    } else {
                        yearParts = [];
                    }
                    ko.mapping.fromJS(yearParts, {}, context.ViewModel.ListModel.SearchViewModel.YearParts);
                });
            } else {
                ko.mapping.fromJS([], {}, context.ViewModel.ListModel.SearchViewModel.YearParts);
            }
        }

        context.LoadSubjectsForList = function () {
            var programId = context.ViewModel.ListModel.SearchViewModel.ProgramId();
            var yearPartId = context.ViewModel.ListModel.SearchViewModel.YearPartId();
            if (programId > 0 && yearPartId > 0) {
                ajaxRequest('/Lookup/GetSubjectsByProgramYearPart', 'GET', { data: { programId: programId, yearPartId: yearPartId } }, function (response) {
                    if (response.IsSuccess) {
                        ko.mapping.fromJS(response.Data, {}, context.ViewModel.ListModel.SearchViewModel.Subjects);
                    } else {
                        showMessage(context.Title, response.Message, 'error');
                    }
                });
            } else {
                ko.mapping.fromJS([], {}, context.ViewModel.ListModel.SearchViewModel.Subjects);
            }
        }


        //region : Index : Start
        context.Initialize = function () {
            ajaxRequest('/Exam/InternalMarks/Initialize', 'GET', {}, function (response) {
                if (response.IsSuccess) {
                    if (!ko.dataFor($('#listView')[0])) {
                        context.ViewModel.ListModel = ko.mapping.fromJS(response.Data, context.Mapping);

                        setTimeout(function () {
                            ko.applyBindings(context.ViewModel.ListModel, $('#listView')[0]);

                        }, 500
                        );
                    }
                    else {
                        ko.mapping.fromJS(response.Data, context.Mapping, context.ViewModel.ListModel);

                    }

                    context.ApplySearchValidation();
                }
                else {
                    showMessage(context.Title, response.Message, 'error');
                }
            });
        }

        context.ApplySearchValidation = function () {
            $('#listForm').validate({
                rules: {
                    AcademicYearId: {
                        required: true
                    },
                    CollegeId: {
                        required: true
                    },
                    ProgramId: {
                        required: true
                    },
                    YearPartId: {
                        required: true
                    }
                }
            });
        }


        //region : Index : End

        //region Create : Start
        context.CreateMapping = {
            create: function (options) {
                var vm = ko.mapping.fromJS(options.data);

                vm.Search = function () {
                    context.CreateSearch();
                }

                vm.LevelId.subscribe(function (newValue) {
                    context.LoadProgram(vm.CollegeID(), newValue)
                })

                vm.CollegeID.subscribe(function (newValue) {
                    context.LoadProgram(newValue, vm.LevelId());
                });

                vm.ProgramId.subscribe(function (newValue) {
                    context.LoadYearPart(newValue);
                    context.LoadSubject();
                });

                vm.YearPartId.subscribe(function (newValue) {
                    context.LoadSubject();
                });

                vm.RenderComplete = function () {
                    debugger;
                    //var subjectInfo = ko.toJS(context.ViewModel.CreateModel.SubjectInfo);
                    //context.ApplyMarksValidation(subjectInfo.InternalTheoryFullMark, subjectInfo.InternalPracticalFullMark);
                    context.SetupAutoFocus();
                }

                return vm;
            }
        }

        context.PrintLedger = function () {
            $(".studentwise-sheet").printThis();
        }

        context.ApplyMarksValidation = function (maxDecimalTheory, maxDecimalPractical) {
            jQuery.validator.addClassRules({
                theoryMarks: {
                    maxlength: 5,
                    number: true,
                    max: maxDecimalTheory
                },
                practicalMarks: {
                    maxlength: 5,
                    number: true,
                    max: maxDecimalPractical
                }
            });

            $('#internalMarksForm').validate();
        }

        context.Save = function () {
            if (!$('#internalMarksForm').valid()) {
                return false;
            }
            var academicYearId = context.ViewModel.CreateModel.SearchModel.AcademicYearId();
            var subjectDetailId = context.ViewModel.CreateModel.SearchModel.SubjectId();
            var records = ko.toJS(context.ViewModel.CreateModel.Records);

            ajaxRequest('/Exam/InternalMarks/Save', 'POST', { data: { model: records, academicYearId: academicYearId, subjectDetailId: subjectDetailId } }, function (response) {
                if (response.IsSuccess) {
                    showMessage(context.Title, response.Message, 'success');
                } else {
                    showMessage(context.Title, response.Message, 'error');
                }
            });
        }

        context.LoadSubject = function () {
            var programId = context.ViewModel.CreateModel.SearchModel.ProgramId();
            var yearPartId = context.ViewModel.CreateModel.SearchModel.YearPartId();
            ajaxRequest('/Lookup/GetSubjectsByProgramYearPart', 'GET', { data: { programId: programId, yearPartId: yearPartId } }, function (response) {
                if (response.IsSuccess) {
                    ko.mapping.fromJS(response.Data, {}, context.ViewModel.CreateModel.SearchModel.Subjects);
                } else {
                    showMessage(context.Title, response.Message, 'error');
                }
            });
        }

        context.CreateSearch = function () {
            if (!$('#searchForm').valid()) {
                return false;
            }
            var model = ko.toJS(context.ViewModel.CreateModel.SearchModel);
            delete model.Search;
            delete model.__ko_mapping__;

            ajaxRequest('/Exam/InternalMarks/SearchInternalMarks', 'POST', { data: { model: model } },
                function (response) {
                    if (response.IsSuccess) {
                        if (!ko.dataFor($('#mainContent')[0])) {
                            context.ViewModel.CreateModel.Records = ko.mapping.fromJS(response.Data.Students, {});
                            context.ViewModel.CreateModel.SubjectInfo = ko.mapping.fromJS(response.Data.SubjectInfo, {});
                            ko.applyBindings(context.ViewModel.CreateModel, $('#mainContent')[0]);
                        } else {
                            ko.mapping.fromJS(response.Data.Students, {}, context.ViewModel.CreateModel.Records);
                            ko.mapping.fromJS(response.Data.SubjectInfo, {}, context.ViewModel.CreateModel.SubjectInfo);
                        }
                    } else {

                    }
                });

        }


        context.LoadProgram = function (newCollegeId, newLevelId) {
            if (newCollegeId > 0 && newLevelId > 0) {
                ajaxRequest('/Lookup/GetProgramByCollege', 'POST', { data: { collegeId: newCollegeId, levelId: newLevelId } }, function (response) {
                    var programs = [];
                    if (response.IsSuccess) {
                        programs = response.Data;
                    } else {
                        programs = [];
                    }
                    ko.mapping.fromJS(programs, {}, context.ViewModel.CreateModel.SearchModel.Programs);
                });
            } else {
                ko.mapping.fromJS([], {}, context.ViewModel.CreateModel.SearchModel.Programs);
            }
        }
        context.LoadYearPart = function (newProgramId) {
            ajaxRequest('/Lookup/GetYearPartByProgram', 'POST', { data: { programId: newProgramId } }, function (response) {
                var yearParts = [];
                if (response.IsSuccess) {
                    yearParts = response.Data;
                } else {
                    yearParts = [];
                }
                ko.mapping.fromJS(yearParts, {}, context.ViewModel.CreateModel.SearchModel.YearParts);
            });
        }

        context.InitializeCreate = function () {


            ajaxRequest('/Exam/InternalMarks/InitializeCreate/',
                'GET',
                { data: {} },
                function (response) {
                    if (response.IsSuccess) {
                        if (!ko.dataFor($('#searchForm')[0])) {
                            context.ViewModel.CreateModel.SearchModel = ko.mapping.fromJS(response.Data, context.CreateMapping);

                            ko.applyBindings(context.ViewModel.CreateModel, $('#searchForm')[0]);
                        } else {
                            ko.mapping.fromJS(response.Data, context.CreateMapping, context.ViewModel.CreateModel.SearchModel);
                        }
                    } else {
                        showMessage(context.Title, response.Message, 'error');
                    }
                });
        }

        context.ApplySearchValidation = function () {
            $('#searchForm').validate({
                rules: {
                    AcademicYearId: {
                        required: true,
                    },
                    CollegeID: {
                        required: true,
                    },
                    ProgramId: {
                        required: true,
                    },
                    YearPartId: {
                        required: true,
                    },
                    SubjectId: {
                        required: true
                    }
                }
            });
        }

    })(emis.internalMarks);
});