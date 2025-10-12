function [alphas, offset] = bitjoy_seqminopt(data, targetLabels, boxConstraints, ...
    kernelFunc, smoOptions)

% http://bitjoy.net/2016/05/02/svm-smo-algorithm/
% 参考文献:
% [1] A Fast Algorithm for Training  Support Vector Machines,
%     http://research.microsoft.com/pubs/69644/tr-98-14.pdf
% [2] CSDN, http://blog.csdn.net/techq/article/details/6171688

N = length(data); % 样本数量
alphas = zeros([N,1]); % 所有拉格朗日乘子初始化为0
offset = 0.0; % 偏移量b也初始化为0

numChanged = 0; % 拉格朗日乘子改变的个数
examineAll = 1; % 是否需要检查所有拉格朗日乘子

% 主流程
while numChanged > 0 || examineAll
    numChanged = 0;
    if examineAll == 1
        for i = 1 : N
            numChanged = numChanged + examineExample(i);
        end
    else
        for i = 1 : N
            if alphas(i) ~= 0 && alphas(i) ~= boxConstraints(i)
                numChanged = numChanged + examineExample(i);
            end
        end
    end
    if examineAll == 1
        examineAll = 0;
    elseif numChanged == 0
        examineAll = 1;
    end
end

    % 计算当前参数下第idx个样本的函数输出
    function [svm_o] = wxpb(idx)
        svm_o = 0.0;
        for j = 1 : N
            svm_o = svm_o + alphas(j) * targetLabels(j) * kernelFunc(data(j,:),data(idx,:));
        end
        svm_o = svm_o + offset;
    end

    % 选定第二个变量i2后，根据max|E1-E2|的启发式规则，选择i1；
    % 如果没有满足条件的i1，返回-1.
    function [i1] = selectSecondChoice(i2, E2)
        i1 = -1;
        maxDelta = -1;
        for j = 1 : N
            if j ~= i2 && alphas(j) ~= 0 && alphas(j) ~= boxConstraints(j)
                Ej = wxpb(j) - targetLabels(j);
                if abs(E2 - Ej) > maxDelta
                    i1 = j;
                    maxDelta = abs(E2 - Ej);
                end
            end
        end
    end

    % 根据选定的两个变量i1,i2，代入更新公式计算；
    % 最后还更新了偏移量offset，也就是y=wx+b中的b。
    function [flag] = takeStep(i1, i2)
        alpha1 = alphas(i1);
        y1 =  targetLabels(i1);
        E1 = wxpb(i1) - y1;
        alpha2 = alphas(i2);
        y2 =  targetLabels(i2);
        E2 = wxpb(i2) - y2;
        s = y1 * y2;
        if y1 ~= y2
            L = max(0, alpha2 - alpha1);
            H = min(boxConstraints(i2), boxConstraints(i1) + alpha2 - alpha1);
        else
            L = max(0, alpha2 + alpha1 - boxConstraints(i1));
            H = min(boxConstraints(i2), alpha2 + alpha1);
        end
        if L == H
            flag = 0;
            return;
        end
        k11 = kernelFunc(data(i1,:),data(i1,:));
        k12 = kernelFunc(data(i1,:),data(i2,:));
        k22 = kernelFunc(data(i2,:),data(i2,:));
        eta = k11 + k22 - 2 * k12;
        if eta > 0
            a2 = alpha2 + y2 * (E1 - E2) / eta;
            %截断
            if a2 < L
                a2 = L;
            elseif a2 > H
                a2 = H;
            end
        else % 并未处理该case，论文[1]公式(19)有更详细的方法
            flag = 0;
            return;
        end
        if abs(a2 - alpha2) < eps * (a2 + alpha2 + eps)
            flag = 0;
            return;
        end
        a1 = alpha1 + s * (alpha2 - a2);
        alphas(i1) = a1;
        alphas(i2) = a2;
        
        % 更新offset
        b1 = offset - E1 - y1 * k11 * (a1 - alpha1) - y2 * k12 * (a2 - alpha2);
        b2 = offset - E2 - y1 * k12 * (a1 - alpha1) - y2 * k22 * (a2 - alpha2);
        if a1 > 0 && a1 < boxConstraints(i1)
            offset = b1;
        elseif a2 > 0 && a2 < boxConstraints(i2)
            offset = b2;
        else
            offset = (b1 + b2) / 2;
        end
        flag = 1;
    end

    % 检查样本。
    % 首先判断i2是否满足KKT条件，如果不满足，
    % 则根据启发式规则再选择i1样本，
    % 然后更新i1和i2的拉格朗日乘子。
    function [flag] = examineExample(i2)
        y2 =  targetLabels(i2);
        alpha2 = alphas(i2);
        E2 = wxpb(i2) - y2;
        r2 = E2 * y2;
        if (r2 < -smoOptions.TolKKT && alpha2 < boxConstraints(i2)) || (r2 > smoOptions.TolKKT && alpha2 > 0)
            i1 = selectSecondChoice(i2, E2);
            if i1 == -1
                i1 = floor(1 + rand() * N); % 随机选一个i1
                while i1 == i2
                    i1 = floor(1 + rand() * N);
                end
                flag = takeStep(i1,i2);
            else
                flag = takeStep(i1,i2);
            end
        else
            flag = 0;
        end
    end
end