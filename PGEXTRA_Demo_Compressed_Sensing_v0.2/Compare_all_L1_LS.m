clear all;
clc;
close all hidden;
show_graph=1;
q_ratio=0.25;
L=10;
m=3;
n=50;
L_f=1;
Dist=50;
eg_num=2;
M_mean=0;
M_var=1;
x_mean=0;
x_div=1;
h_mean=0;
h_var=0.1;
zero_per=0.8;
lambda_ori=1;
EXTRA_coef=[0.9,1.0,1.2];
DISTA_coef=[1,2.5,5];
len_alpha_set=length(EXTRA_coef);
per=4/L;
quiet=1;
seed2=init_rand(2001);
[kappa_G,P,per_t,fig_G]=GGen(L,per,'random',show_graph,quiet,round(per*(L-1)));

% go_on=input('Are you going to continue: ','s');
% if go_on=='n'
% return;
% end;

max_iter=4000;
seed=init_rand(2013);
[M_ori,x_ori,y_ori,alpha_DISTA_ori]=l1_ls_random_data_producer(m,n,L,M_mean,M_var,x_mean,x_div,h_mean,h_var,Dist,zero_per,lambda_ori,L_f,2*max_iter,seed);
x_0=zeros(n,L);
dirname=['PG_EXTRA_',num2str(seed2),'_',num2str(seed)];
cmd_mkdir=['mkdir ' dirname];
system(cmd_mkdir);
Deg=sum(P);
L_neg=diag(Deg)-P;
L_pos=diag(Deg)+P;
eig_L_neg=sort(eig(L_neg),'ascend');
eye_L=eye(L);
%%
%FDLA

% [W_FDLA,~]=fdla_symmetric_nneg(P);
% eig_W_FDLA=eig(W_FDLA)

% [W_FDLA,~]=fdla_symmetric(P);
% eig_W_FDLA=eig(W_FDLA)

[W_local_degree]=local_degree(P,7);
eig_W_local_degree=eig(W_local_degree)

% [W_EXTRA,BW_EXTRA,~]=fastest_EXTRA(P);
% eig_W_EXTRA=eig(W_EXTRA)

% [W_EXTRA,BW_EXTRA,~]=fastest_EXTRA_sym(P);
% eig_W_EXTRA=eig(W_EXTRA)

% [W_EXTRA,BW_EXTRA,~]=fastest_EXTRA_nneg(P);
% eig_W_EXTRA=eig(W_EXTRA)

% [W_EXTRA,BW_EXTRA,~]=fastest_EXTRA_W_BW(P);
% eig_W_EXTRA=eig(W_EXTRA)

% [W_EXTRA,BW_EXTRA,~]=fastest_EXTRA_sec2(P);
% eig_W_EXTRA=sort(eig(W_EXTRA),'ascend')


% tao=2*max(eig_L_neg);
% tao=eig_L_neg(end)/2;
% tao=eig_L_neg(end);

% tao=(eig_L_neg(end)+eig_L_neg(2))/2;
% W_Lap=eye_L-L_neg/tao;
% eig_Lap=eig(W_Lap)

% keyboard;
%%
% Phi=W_EXTRA;
% Psi=BW_EXTRA;

Phi=W_local_degree;
Psi=(eye_L+Phi)/2;

% Phi=W_FDLA;
% Psi=(eye_L+Phi)/2;

Phi_DISTA=Phi;

min_eig_Psi=sort(eig(Psi),'ascend');
for temp_i=1:L
    if min_eig_Psi(temp_i)>0.001
        min_eig_Psi=min_eig_Psi(temp_i);
        break;
    end;
end;
alpha_ori=2*min_eig_Psi/L_f;
alpha_DISTA_ori=+inf;
for l=1:L
    temp=1/norm(M_ori(:,:,l),2)^2;
    if temp<alpha_DISTA_ori
        alpha_DISTA_ori=temp;
    end;
end;

x_star=x_ori;
disp(strcat('alpha_set=',num2str(reshape(alpha_ori,length(alpha_ori),1))));
legend_cell=cell(eg_num*len_alpha_set,1);
count=0;
err_EX=cell(len_alpha_set,1);
err_DISTA=cell(len_alpha_set,1);
succ_EX=cell(len_alpha_set,1);
succ_DISTA=cell(len_alpha_set,1);

%%
lambda_vec=lambda_ori/L;
for l_alpha=1:len_alpha_set

    alpha_EX=EXTRA_coef(l_alpha)*alpha_ori;
    alpha_DISTA=DISTA_coef(l_alpha)*alpha_DISTA_ori;

    err_EX{l_alpha}=zeros(max_iter,1);
    succ_EX{l_alpha}=zeros(max_iter,1);
    x_new=x_0;
    x_EX=x_0;
    x_EX_half=x_0;
    err_EX{l_alpha}(1)=norm(x_EX-x_star,'fro');
    for l=1:L
        x_EX_half(:,l)=x_EX*Phi(:,l)-alpha_EX*M_ori(:,:,l)'*(M_ori(:,:,l)*x_EX(:,l)-y_ori(:,l));
        x_new(:,l)=wthresh(x_EX_half(:,l),'s',alpha_EX*lambda_vec);
    end;
    succ_EX{l_alpha}(1)=norm(x_new-x_EX,'fro');
    
    err_DISTA{l_alpha}=zeros(max_iter,1);
    succ_DISTA{l_alpha}=zeros(max_iter,1);
    x_DISTA=x_0;
    err_DISTA{l_alpha}(1)=norm(x_DISTA-x_star,'fro');
    x_bar=x_DISTA*Phi_DISTA; 
    
    for i=1:max_iter

        j=i+1;
        x_old=x_EX;
        x_EX=x_new;
        err_EX{l_alpha}(j)=norm(x_EX-x_star,'fro');
        if err_EX{l_alpha}(i)<10^-15
            err_EX{l_alpha}(i)=10^-15;
        end;
        for l=1:L
            x_EX_half(:,l)=x_EX*Phi(:,l)+x_EX_half(:,l)-x_old*Psi(:,l)-alpha_EX*M_ori(:,:,l)'*M_ori(:,:,l)*(x_EX(:,l)-x_old(:,l));
            x_new(:,l)=wthresh(x_EX_half(:,l),'s',alpha_EX*lambda_vec);
        end;
        succ_EX{l_alpha}(j)=norm(x_new-x_EX,'fro');
%         q_ratio=0.5-0.4*(i/max_iter);
        
        if mod(i,2)==1
            for l=1:L
                x_DISTA_temp(:,l)=wthresh((1-q_ratio)*x_bar*Phi_DISTA(:,l)+q_ratio*(x_DISTA(:,l)+alpha_DISTA*M_ori(:,:,l)'*(y_ori(:,l)-M_ori(:,:,l)*x_DISTA(:,l))),'s',q_ratio*lambda_vec);
            end;
            succ_DISTA{l_alpha}(i)=norm(x_DISTA_temp-x_DISTA,'fro');   
            x_DISTA=x_DISTA_temp;
        else
            x_bar=x_DISTA*Phi;
            succ_DISTA{l_alpha}(i)=succ_DISTA{l_alpha}(i-1);
        end;
        err_DISTA{l_alpha}(j)=norm(x_DISTA-x_star,'fro');
        if err_DISTA{l_alpha}(i)<10^-15
            err_DISTA{l_alpha}(i)=10^-15;
        end; 
    end;
end;    

samp_size=round(max_iter/30);
samp_size_2=round(max_iter/30);   
leg_count=0;

%%
figure(1);
semilogy(1:samp_size_2:max_iter,err_DISTA{1}(1:samp_size_2:max_iter)/err_DISTA{1}(1),'--','LineWidth',2);hold all;
leg_count=leg_count+1;legend_cell{leg_count}=strcat(['DISTA, parameter $$\tau=',num2str(DISTA_coef(1),'%1.1f'),'\tau_0$$']);
if length(err_DISTA)>1
    semilogy(1:samp_size:max_iter,err_DISTA{2}(1:samp_size:max_iter)/err_DISTA{2}(1),'--x','LineWidth',2);hold all;
    leg_count=leg_count+1;legend_cell{leg_count}=strcat(['DISTA, parameter $$\tau=',num2str(DISTA_coef(2),'%1.1f'),'\tau_0$$']);
end;
if length(err_DISTA)>2
    semilogy(1:samp_size:max_iter,err_DISTA{3}(1:samp_size:max_iter)/err_DISTA{3}(1),'--o','LineWidth',2);hold all;
    leg_count=leg_count+1;legend_cell{leg_count}=strcat(['DISTA, parameter $$\tau=',num2str(DISTA_coef(3),'%1.1f'),'\tau_0$$']);
end;

semilogy(1:samp_size_2:max_iter,err_EX{1}(1:samp_size_2:max_iter)/err_EX{1}(1),'-','LineWidth',2);hold all;
leg_count=leg_count+1;legend_cell{leg_count}=strcat(['PG-EXTRA, step size $$\alpha=',num2str(EXTRA_coef(1),'%1.1f'),'\alpha_0$$']);
if length(err_EX)>1
    semilogy(1:samp_size_2:max_iter,err_EX{2}(1:samp_size_2:max_iter)/err_EX{2}(1),'-x','MarkerSize',8,'LineWidth',2);hold all;
    leg_count=leg_count+1;legend_cell{leg_count}=strcat(['PG-EXTRA, step size $$\alpha=',num2str(EXTRA_coef(2),'%1.1f'),'\alpha_0$$']);
end;
if length(err_EX)>2
    semilogy(1:samp_size_2:max_iter,err_EX{3}(1:samp_size_2:max_iter)/err_EX{3}(1),'-o','MarkerSize',8,'LineWidth',2);hold all;
    leg_count=leg_count+1;legend_cell{leg_count}=strcat(['PG-EXTRA, step size $$\alpha=',num2str(EXTRA_coef(3),'%1.1f'),'\alpha_0$$']);
end;

fig1=figure(1);legend(legend_cell,'interpreter','latex','Location','SouthEast');
xlabel('$$k$$','FontSize',18,'Interpreter','latex');
ylabel('Relative Error','FontSize',18,'Interpreter','latex');
set(gca,'FontSize',16);set(gca,'LineWidth',2);
ylim([10^-10,10^0.5]);

%%
figure(2);
semilogy(1:samp_size:max_iter,succ_DISTA{1}(1:samp_size:max_iter),'--','LineWidth',2);hold all;
if length(err_DISTA)>1
    semilogy(1:samp_size_2:max_iter,succ_DISTA{2}(1:samp_size_2:max_iter),'--x','LineWidth',2);hold all;
end;
if length(err_DISTA)>2
    semilogy(1:samp_size_2:max_iter,succ_DISTA{3}(1:samp_size_2:max_iter),'--o','LineWidth',2);hold all;
end;

semilogy(1:samp_size:max_iter,succ_EX{1}(1:samp_size:max_iter),'-','LineWidth',2);hold all;
if length(err_EX)>1
    semilogy(1:samp_size_2:max_iter,succ_EX{2}(1:samp_size_2:max_iter),'-x','MarkerSize',8,'LineWidth',2);hold all;
end;
if length(err_EX)>2
    semilogy(1:samp_size_2:max_iter,succ_EX{3}(1:samp_size_2:max_iter),'-o','MarkerSize',8,'LineWidth',2);hold all;
end;

fig2=figure(2);legend(legend_cell,'interpreter','latex','Location','SouthEast');
xlabel('$$k$$','FontSize',18,'Interpreter','latex');
ylabel('Successive Difference','FontSize',18,'Interpreter','latex');
set(gca,'FontSize',16);set(gca,'LineWidth',2);
ylim_temp=ylim;
ylim([10^-10,ylim_temp(2)]);

%%
saveas(fig1,[dirname,'\Conv_DCS.fig']);
saveas(fig1,[dirname,'\Conv_DCS.jpg']);
saveas(fig1,[dirname,'\Conv_DCS.eps'],'psc2');
saveas(fig1,[dirname,'\Conv_DCS'],'pdf');

saveas(fig2,[dirname,'\Succ_DCS.fig']);
saveas(fig2,[dirname,'\Succ_DCS.jpg']);
saveas(fig2,[dirname,'\Succ_DCS.eps'],'psc2');
saveas(fig2,[dirname,'\Succ_DCS'],'pdf');

figure,
plot(x_EX(:,1));
hold all;
plot(x_star(:,1));
hold all;
plot(x_DISTA(:,1));
legend('x_{EX}','x^*','x_{DISTA}');

