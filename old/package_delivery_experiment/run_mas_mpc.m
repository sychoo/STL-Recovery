% This file runs experiment to of a
% multi-agent surveillance system subject to an STL formula
% with an MPC strategy

clear
config_mas;

alpha_value = 25;
beta_value = 20;

I1 = eye(3);
I2 = eye(2);
J1 = [1, delta_t; 0, 1];
J2 = [location_shift_rate; delta_t];

A = kron(I1,J1);
A(end,end) = 0;
A = kron(I2, A);
B = kron(I1,J2);
B(end,end) = charging_rate1;
B = kron(I2, B);
B(end,end) = charging_rate2;

c = [0;0;0;0;0;-1];
c = [c;c];

num_stations = 2;
[charg_left_bottoms, charg_right_tops] = charging_stations(num_stations);
num_regions = 2;
[surveil_left_bottoms, surveil_right_tops] = surveillance_spots(num_regions);

H = 60;  % horizon
u_lim = 1; % bounds for the control action
p_lim = 10; % bounds for the battery power

surveil_a1 = 0; surveil_b1 = 30;
surveil_a2 = 30; surveil_b2 = 60;

% robot 1
x_01x= 1.1;
x_01y= 0.5;
x_01p= 5;
% robot 2
x_02x= 7;
x_02y= 2;
x_02p= 13;

x_01 = [x_01x, 0, x_01y, 0, x_01p, -1]';
x_02 = [x_02x, 0, x_02y, 0, x_02p, -1]';

episode_length = 60;

disp('Running deadline-driven package delivery with DM...');

for num_dm = 2:4
    switch num_dm
        case 1
            current_dm = @pro_rec_dm;
            fprintf("Use pro-recoverability DM.\n");
        case 2
            current_dm = @pro_dur_dm;
            fprintf("Use pro-durability DM.\n");
        case 3
            current_dm = @adaptive_dm;
            fprintf("Use adaptive DM.\n");
        case 4
            current_dm = @mini_dis_dm;
            fprintf("Use minimal-distance DM.\n");
    end

    states = zeros(12,episode_length);
    controls = zeros(6,episode_length-1);
    pe = zeros(1,episode_length-1);
    optimal_solution_all = cell(0);
    optimal_set_all=cell(0);
    optimal_states_all=cell(0);
    solve_time_all = cell(0);

    states(:,1) = [x_01;x_02];

    %%
    for ts = 1:episode_length-1

        current_state = states(:,ts);

        % constrain the control actions
        u1 = sdpvar(2,H-1,'full'); % control of movement
        u2 = sdpvar(2,H-1,'full'); % control of movement

        e1 = binvar(1,H-1,'full'); % control of charging
        e2 = binvar(1,H-1,'full'); % control of charging

        constraints = [];
        % constrain the control actions
        for k = 1:H-1
            constraints = [constraints; u1(1,k) <= u_lim; u1(1,k)>=-u_lim];
            constraints = [constraints; u1(2,k) <= u_lim; u1(2,k)>=-u_lim];
            constraints = [constraints; u2(1,k) <= u_lim; u2(1,k)>=-u_lim];
            constraints = [constraints; u2(2,k) <= u_lim; u2(2,k)>=-u_lim];
        end

        % system constraints (dynamics)
        % x_n = sdpvar(12,H,'full'); % with H number of points, signal length is H-1
        % constraints = [constraints; x_n(1:6,1) == x_01; x_n(7:12,1) == x_02];
        x = current_state;
        % compute system constraints
        for i = 1:H-1
            x_k = x(:,i);
            u_k = [u1(:,i);e1(:,i);u2(:,i);e2(:,i)];
            x_kp1 = A*x_k + B*u_k + c;
            x = [x, x_kp1];
        end
        x1 = [x(1, :); x(3, :)];
        x2 = [x(7, :); x(9, :)];
        p1 = x(5,:);
        p2 = x(11,:);
        % constrain the charging control action (charged when robot is in one of the charging stations)
        % charging stations
        % robot 1:
        [constr_charg_agent1_region1, z_charg_agent1_region1] = bool_mu_region(x1', charg_left_bottoms(1,1), charg_right_tops(1,1),...
            charg_left_bottoms(1,2), charg_right_tops(1,2)); % 1st agent in 1st charging region
        constraints = [constraints; constr_charg_agent1_region1];
        [constr_charg_agent1_region2, z_charg_agent1_region2] = bool_mu_region(x1', charg_left_bottoms(2,1), charg_right_tops(2,1),...
            charg_left_bottoms(2,2), charg_right_tops(2,2)); % 1st agent in 2nd charging region
        constraints = [constraints; constr_charg_agent1_region2];
        z_charg_agent1 = binvar(1,H,'full');
        for i = 1:H % 1st agent is charged in either charging region
            [constr_charg_agent1, z_charg_agent1(i)] = bool_or([z_charg_agent1_region1(i);z_charg_agent1_region2(i)]);
            constraints = [constraints; constr_charg_agent1];
        end
        constraints = [constraints; e1 == z_charg_agent1(1:end-1)];
        % % robot 2:
        [constr_charg_agent2_region1, z_charg_agent2_region1] = bool_mu_region(x2', charg_left_bottoms(1,1), charg_right_tops(1,1),...
            charg_left_bottoms(1,2), charg_right_tops(1,2)); % 2nd agent in 1st charging region
        constraints = [constraints; constr_charg_agent2_region1];
        [constr_charg_agent2_region2, z_charg_agent2_region2] = bool_mu_region(x2', charg_left_bottoms(2,1), charg_right_tops(2,1),...
            charg_left_bottoms(2,2), charg_right_tops(2,2)); % 2nd agent in 2nd charging region
        constraints = [constraints; constr_charg_agent2_region2];
        z_charg_agent2 = binvar(1,H,'full');
        for i = 1:H % 2nd agent is charged in either charging region
            [constr_charg_agent2, z_charg_agent2(i)] = bool_or([z_charg_agent2_region1(i);z_charg_agent2_region2(i)]);
            constraints = [constraints; constr_charg_agent2];
        end
        constraints = [constraints; e2 == z_charg_agent2(1:end-1)];

        % power requirement: battery power >= p_lim
        [constr_p1, z_p1] = bool_mu(p1(2:end)', 1, p_lim);
        constraints = [constraints;constr_p1];
        [constr_p2, z_p2] = bool_mu(p2(2:end)', 1, p_lim);
        constraints = [constraints;constr_p2];
        % the initial power requirement, the power level before the current time
        % window >= p_lim
        [constr_p1_init_all, z_p1_init_all] = bool_mu([p1(1)';states(5,1:ts)'], 1, p_lim);
        constraints = [constraints;constr_p1_init_all];
        [constr_p1_init, z_p1_init] = bool_and(z_p1_init_all);
        constraints = [constraints;constr_p1_init];
        [constr_p2_init_all, z_p2_init_all] = bool_mu([p2(1)';states(11,1:ts)'], 1, p_lim);
        constraints = [constraints;constr_p2_init_all];
        [constr_p2_init, z_p2_init] = bool_and(z_p2_init_all);
        constraints = [constraints;constr_p2_init];
        z_p = sdpvar(H,1,'full');
        for i =2:H       %%% change the range of power requirement here
            [constr_p, z_p(i)] = bool_and([z_p1(i-1); z_p2(i-1)]);
            constraints = [constraints;constr_p];
        end
        [constr_p_1, z_p(1)] = bool_and([z_p1_init; z_p2_init]);
        constraints = [constraints;constr_p_1];
        % surveillance requirement: every surveillance region needs to be entered
        % by at least one robot every 30 steps.
        % region 1:
        [constr_surveil_agent1_region1, z_surveil_agent1_region1] = bool_mu_region(x1', surveil_left_bottoms(1,1), surveil_right_tops(1,1),...
            surveil_left_bottoms(1,2), surveil_right_tops(1,2)); % 1st agent in 1st charging region
        constraints = [constraints; constr_surveil_agent1_region1];
        [constr_surveil_agent2_region1, z_surveil_agent2_region1] = bool_mu_region(x2', surveil_left_bottoms(1,1), surveil_right_tops(1,1),...
            surveil_left_bottoms(1,2), surveil_right_tops(1,2)); % 2nd agent in 1st charging region
        constraints = [constraints; constr_surveil_agent2_region1];
        z_surveil_region1 = binvar(H,1,'full');
        for i = 1:H % region 1 is surveillentd by either robot
            [constr_surveil_region1, z_surveil_region1(i)] = bool_or([z_surveil_agent1_region1(i);z_surveil_agent2_region1(i)]);
            constraints = [constraints; constr_surveil_region1];
        end
        if ts <= surveil_b1+1
            [constr_suveil_region1_finally1, z_suveil_region1_finally1] = bool_finally(z_surveil_region1, surveil_a1, surveil_b1-ts+1);
            constraints = [constraints; constr_suveil_region1_finally1]; % region 1 is visited the 1st time
            [constr_suveil_region1_finally2, z_suveil_region1_finally2] = bool_finally(z_surveil_region1, surveil_a2-ts+1, surveil_b2-ts+1);
            constraints = [constraints; constr_suveil_region1_finally2]; % region 1 is visited the 2nd time
            z_suveil_region1_finally_and = sdpvar(H,1,'full');
            for i = 1:H % region 1 is visited twice
                [constr_surveil_region1_finally_and, z_suveil_region1_finally_and(i)] = bool_and([z_suveil_region1_finally1(i);z_suveil_region1_finally2(i)]);
                constraints = [constraints; constr_surveil_region1_finally_and];
            end
        elseif ts <= surveil_b2+1
            [constr_surveil_region1_finally_and, z_suveil_region1_finally_and] = bool_finally(z_surveil_region1, 0, surveil_b2-ts+1);
            constraints = [constraints; constr_surveil_region1_finally_and]; % region 1 is visited the 1st time
        end

        % % region 2:
        [constr_surveil_agent1_region2, z_surveil_agent1_region2] = bool_mu_region(x1', surveil_left_bottoms(2,1), surveil_right_tops(2,1),...
            surveil_left_bottoms(2,2), surveil_right_tops(2,2)); % 1st agent in 2nd charging region
        constraints = [constraints; constr_surveil_agent1_region2];
        [constr_surveil_agent2_region2, z_surveil_agent2_region2] = bool_mu_region(x2', surveil_left_bottoms(2,1), surveil_right_tops(2,1),...
            surveil_left_bottoms(2,2), surveil_right_tops(2,2)); % 2nd agent in 1st charging region
        constraints = [constraints; constr_surveil_agent2_region2];
        z_surveil_region2 = binvar(H,1,'full');
        for i = 1:H % region 2 is surveillentd by either robot
            [constr_surveil_region2, z_surveil_region2(i)] = bool_or([z_surveil_agent1_region2(i);z_surveil_agent2_region2(i)]);
            constraints = [constraints; constr_surveil_region2];
        end
        if ts <= surveil_b1+1
            [constr_suveil_region2_finally1, z_suveil_region2_finally1] = bool_finally(z_surveil_region2, surveil_a1, surveil_b1-ts+1);
            constraints = [constraints; constr_suveil_region2_finally1]; % region 2 is visited the 1st time
            [constr_suveil_region2_finally2, z_suveil_region2_finally2] = bool_finally(z_surveil_region2, surveil_a2-ts+1, surveil_b2-ts+1);
            constraints = [constraints; constr_suveil_region2_finally2]; % region 2 is visited the 2nd time
            z_suveil_region2_finally_and = sdpvar(H,1,'full');
            for i = 1:H % region 2 is visited twice
                [constr_surveil_region2_finally_and, z_suveil_region2_finally_and(i)] = bool_and([z_suveil_region2_finally1(i);z_suveil_region2_finally2(i)]);
                constraints = [constraints; constr_surveil_region2_finally_and];
            end
        elseif ts <= surveil_b2+1
            [constr_surveil_region2_finally_and, z_suveil_region2_finally_and] = bool_finally(z_surveil_region1, 0, surveil_b2-ts+1);
            constraints = [constraints; constr_surveil_region2_finally_and]; % region 1 is visited the 1st time
        end

        % region 1 AND 2:
        z_suveil = sdpvar(H,1,'full');
        for i = 1:H % Both regions 1 and 2 are visited twice
            [constr_surveil, z_suveil(i)] = bool_and([z_suveil_region1_finally_and(i);z_suveil_region2_finally_and(i)]);
            constraints = [constraints; constr_surveil];
        end
        % power requirement AND surveillance requirement
        z_p_and_surveil = sdpvar(H,1,'full');
        for i =1:H %%%%%%%%%%%%%%%%%%%%%%
            [constr_p_and_surveil, z_p_and_surveil(i)] = bool_and([z_p(i); z_suveil(i)]);
            constraints = [constraints;constr_p_and_surveil];
        end

        % use overall z to compute t_rec and t_dur
        % t_rec and t_dur via the overall z
        [constr_trec, trec_value] = trec(z_p_and_surveil);
        constraints = [constraints;constr_trec];

        [constr_tdur, tdur_value] = tdur(z_p_and_surveil);
        constraints = [constraints;constr_tdur];
        % constraints = [constraints; trec_value(1) <= 16 ];

        % optimize
        options = sdpsettings('debug', 0,...
            'solver', 'gurobi', ...
            'verbose',0);
        objective = -tdur_value(1);
        % objective = trec_value(1);

%         if mod(ts,10) == 1
            fprintf('Progress: %d/%d\n', ts, episode_length-1);
%         end

        [optimal_solution,optimal_set, optimal_states, num_pe, solve_times] = rescon(constraints, trec_value(1), objective, x, [u1;e1;u2;e2], options, H, alpha_value, beta_value);

        pe(ts) = num_pe;
        optimal_solution_all{ts} = optimal_solution;
        optimal_set_all{ts} = optimal_set;
        optimal_states_all{ts} = optimal_states;
        solve_time_all{ts} = solve_times;
        os_index = current_dm(optimal_solution_all{1},alpha_value,H-beta_value);
        selected_controls = optimal_set_all{1}{os_index};
        controls(:,ts) = selected_controls(:,ts);
        % system evolve
        states(:,ts+1) = A*states(:,ts)+B*controls(:,ts)+ c;

    end

    switch num_dm
        case 1
            save ../experiment_data/del_mpc_prorec.mat optimal_solution_all optimal_set_all optimal_states_all pe controls states solve_time_all
        case 2
            save ../experiment_data/del_mpc_produr.mat optimal_solution_all optimal_set_all optimal_states_all pe controls states solve_time_all
        case 3
            save ../experiment_data/del_mpc_adaptive.mat optimal_solution_all optimal_set_all optimal_states_all pe controls states solve_time_all
        case 4
            save ../experiment_data/del_mpc_mindis.mat optimal_solution_all optimal_set_all optimal_states_all pe controls states solve_time_all
    end

end