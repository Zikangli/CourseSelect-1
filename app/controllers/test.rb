class CoursesController < ApplicationController

  before_action :student_logged_in, only: [:select, :quit, :list]
  before_action :teacher_logged_in, only: [:new, :create, :edit, :destroy, :update]
  before_action :logged_in, only: :index

  #-------------------------for teachers----------------------

  def new
    @course=Course.new
  end

  def create
    @course = Course.new(course_params)
    if @course.save
      current_user.teaching_courses<<@course
      redirect_to courses_path, flash: {success: "新课程申请成功"}
    else
      flash[:warning] = "信息填写有误,请重试"
      render 'new'
    end
  end

  def edit
    @course=Course.find_by_id(params[:id])
  end

  def update
    @course = Course.find_by_id(params[:id])
    if @course.update_attributes(course_params)
      flash={:info => "更新成功"}
    else
      flash={:warning => "更新失败"}
    end
    redirect_to courses_path, flash: flash
  end

  def destroy
    @course=Course.find_by_id(params[:id])
    current_user.teaching_courses.delete(@course)
    @course.destroy
    flash={:success => "成功删除课程: #{@course.name}"}
    redirect_to courses_path, flash: flash
  end
  
  def open
    @course = Course.find_by_id(params[:id])
    @course.update_attributes(:open=>true)
    redirect_to courses_path, flash: {:success => "已经成功开放该课程:#{ @course.name}"}
  end

  def close
    @course = Course.find_by_id(params[:id])
    @course.update_attributes(:open=>false)
    redirect_to courses_path, flash: {:success => "已经成功关闭该课程:#{ @course.name}"}
  end
  
  def courseplan
      @course=Course.find_by_id(params[:id])
  end

  #-------------------------for students----------------------



  def list
     #   按照关键词（课程名称、教师名）或者下拉列表进行查询
    @course = Array.new
    @queryType = params[:queryType].to_i
    if @queryType.nil? == false
     @queryinfo = params[:query]
     if @queryinfo.nil? == false
        if @queryType == 2 
            @course = Course.where("name like '%#{@queryinfo}%'")  
        elsif @queryType == 10
            @teacherName = User.where("name like '%#{@queryinfo}%'")
            @teacherName.each do |teacherSingle|
                teacherSingle.teaching_courses.each do |courseSingle|
                    @course.push courseSingle
                end
            end
        elsif @queryType == 1
            @course = Course.where("course_code like '#{@queryinfo}%'")
        elsif @queryType == 3
            @course = Course.where("credit like '#{@queryinfo}'")
        elsif @queryType == 4
            @course = Course.where("course_type like '#{@queryinfo}'")
        elsif @queryType == 5
            @course = Course.where("teaching_type like '#{@queryinfo}'")
        elsif @queryType == 6
            @course = Course.where("exam_type like '#{@queryinfo}'")
        elsif @queryType == 7
            @course = Course.where("class_room like '#{@queryinfo}'")
        elsif @queryType == 8
            @course = Course.where("course_week like '#{@queryinfo}'")
        elsif @queryType == 9
            @course = Course.where("course_time like '#{@queryinfo}'")    
        else
            @course = Course.all
        end
     else
         @course=Course.all 
     end
    else
        @course = Course.all
    end
   
    
    @course=@course-current_user.courses
    @course_true = Array.new
    @course.each do |single|
      if single.open then
        @course_true.push single
      end
    end
  end

  
  def tranform_course_time(course,single)#课时间类型转换函数  #最好改成直输入一个变量的函数，因为两个参数类型一样
                                         #操作也一样，再写一个去变量值的方法。不要用全局变量
    left_bracket=course.index("(")
    right_bracket=course.index(")")
    mid_line=course.index("-")
       
    left_bracket1=single.index("(")
    right_bracket1=single.index(")")
    mid_line1=single.index("-")
    
    $day_of_week=course[0..left_bracket-1]
    first_class=course[left_bracket+1..mid_line-1]
    $first_class=first_class.to_i(base=10) #转化成数字，生成课程的时候要用
    last_class=course[mid_line+1..right_bracket-1]
    $last_class=last_class.to_i(base=10) #转化成数字，生成课程的时候要用
      
    $day_of_week1=single[0..left_bracket1-1]
    first_class1=single[left_bracket1+1..mid_line1-1]
    $first_class1=first_class1.to_i(base=10) #转化成数字，生成课程的时候要用
    last_class1=single[mid_line1+1..right_bracket1-1]
    $last_class1=last_class1.to_i(base=10) #转化成数字，生成课程的时候要用
    
  end

  def test_course_conflict(course)
    current_user.courses.each do |single|
      tranform_course_time(course.course_time.strip,single.course_time.strip)
      #if single.course_time == course.course_time #冲突  最好写成一个方法判断是否冲突
      if $day_of_week==$day_of_week1
        if $last_class>= $first_class1 or $first_class<=$last_class1
          return current_user.course_not_conflict = false
        end
      else  #
        break
      end
      
    end
  end


  def select                                #选课为什么不修改选课人数    #已修改 2017.1.1
    @course=Course.find_by_id(params[:id])  #当前选的课程，检查无冲突再加入
    test_course_conflict(@course)
    if current_user.course_not_conflict #无冲突
      current_user.courses<<@course    
      @grades=current_user.grades.find_by(course_id: params[:id])
      @grades.update_attributes(:degree => false)
      if @course.student_num.nil?
        @course.student_num=0
      end
      @course.student_num +=1
      @course.update_attributes(:student_num => @course.student_num) 
      flash={:success => "成功选择课程为非学位课: #{@course.course_code}, #{@course.name}, #{@course.teacher.name }, #{@course.course_time}"}
      redirect_to list_courses_path, flash: flash   #选完课后应停留在选课页面，否则继续选课很麻烦
    else 
      flash={:danger => "选课冲突！冲突课程: #{@course.course_code}, #{@course.name}, #{@course.teacher.name }, #{@course.course_time}"}
      redirect_to courses_path, flash: flash
    end
  end
  
  
  def selectasdegree
    @course=Course.find_by_id(params[:id])  #当前选的课程，检查无冲突再加入
    test_course_conflict(@course)
    if current_user.course_not_conflict #无冲突
      current_user.courses<<@course    
      @grades=current_user.grades.find_by(course_id: params[:id])
      @grades.update_attributes(:degree => true)
      if @course.student_num.nil?
        @course.student_num=0
      end
      @course.student_num +=1
      @course.update_attributes(:student_num => @course.student_num) 
      flash={:success => "成功选择课程为学位课: #{@course.course_code}, #{@course.name}, #{@course.teacher.name}, #{@course.course_time}"}
      redirect_to list_courses_path, flash: flash   #选完课后应停留在选课页面，否则继续选课很麻烦
    else 
      flash={:danger => "选课冲突！冲突课程: #{@course.course_code}, #{@course.name}, #{@course.teacher.name}, #{@course.course_time}"}
      redirect_to courses_path, flash: flash
    end
  end

  def quit
    @course=Course.find_by_id(params[:id])
    current_user.courses.delete(@course)
    @course.student_num -=1
    @course.update_attributes(:student_num => @course.student_num) 
    flash={:success => "成功退选课程: #{@course.name}"}
    redirect_to courses_path, flash: flash
  end
  
  def credittips
    @courses=current_user.courses
    @grades=current_user.grades
    @chosen_credit_all = 0.0
    @chosen_credit_public = 0.0
    @chosen_credit_major = 0.0
    @courses.each do |course|
      @chosen_credit_all = @chosen_credit_all+ course.credit[-3..-1].to_f
      if course.course_type == "公共选修课" then
         @chosen_credit_public = @chosen_credit_public+course.credit[-3..-1].to_f
      end
      if course.course_type == "专业核心课" then
         @chosen_credit_major = @chosen_credit_major+course.credit[-3..-1].to_f
      end
    end
    
   @obtained_credit_pubic = 0.0
   @obtained_credit_major = 0.0
   @obtained_credit_all = 0.0
   @grades.each do |grade|
      if grade.grade.nil? == false
         @obtained_credit_all += grade.course.credit[-3..-1].to_f
         if grade.course.course_type == "公共选修课"
            @obtained_credit_public += grade.course.credit[-3..-1].to_f
         end
         if grade.course.course_type == "专业核心课"
             @obtained_credit_major += grade.course.credit[-3..-1].to_f
         end
      end
   end
  end
  
 
 def filter
    redirect_to list_courses_path(params)
    
 end
 
 def modifydegree
    @grades=current_user.grades.find_by(course_id: params[:id])
    if @grades.degree then
      @grades.update_attributes(:degree => false)
      flash={:success => "更改为非学位课"}
    else
      @grades.update_attributes(:degree => true)
      flash={:success => "更改为学位课"}
    end
    redirect_to courses_path, flash: flash
 end

  #-------------------------for both teachers and students----------------------

  def index
    @course=current_user.teaching_courses if teacher_logged_in?
    @course=current_user.courses if student_logged_in?
    
    @course_all=Course.all
    @course_all=@course_all-@course
    @course_true = Array.new
    @course_all.each do |single|
      if single.open then
        @course_true.push single
      end
    end
  end


  private

  # Confirms a student logged-in user.
  def student_logged_in
    unless student_logged_in?
      redirect_to root_url, flash: {danger: '请登录'}
    end
  end

  # Confirms a teacher logged-in user.
  def teacher_logged_in
    unless teacher_logged_in?
      redirect_to root_url, flash: {danger: '请登录'}
    end
  end

  # Confirms a  logged-in user.
  def logged_in
    unless logged_in?
      redirect_to root_url, flash: {danger: '请登录'}
    end
  end

  def course_params
    params.require(:course).permit(:course_code, :name, :course_type, :teaching_type, :exam_type,
                                   :credit, :limit_num,  :class_room, :course_time, 
                                   :course_week)
  end


end